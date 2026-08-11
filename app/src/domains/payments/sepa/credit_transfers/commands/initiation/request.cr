module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Initiation
    module Commands
      struct Request < ES::Command
        getter r : Payments::Sepa::CreditTransfers::Api::Requests::CreditTransferRequest
        getter actor_id : UUID
        getter scope_id : UUID

        def initialize(@aggregate_id : UUID, @r, @actor_id, @scope_id)
        end
      end

      class RequestHandler < ES::CommandHandler(Request)
        def handle(command : Request)
          r = command.r
          payment_id = command.aggregate_id

          # Resolve execution date — default to today if not provided
          execution_date = Time.utc
          if (ed = r.execution_date)
            begin
              execution_date = Time::Format::ISO_8601_DATE.parse(ed)
            rescue
              raise CrystalBank::Exception::InvalidArgument.new("Invalid execution_date format, expected YYYY-MM-DD")
            end
          end

          # Resolve end-to-end ID — auto-generate if not provided
          end_to_end_id = r.end_to_end_id || UUID.random.to_s.delete("-")[0, 35]

          # Validate creditor IBAN
          raise CrystalBank::Exception::InvalidArgument.new("Invalid creditor IBAN") unless CrystalIBAN::Validator.valid?(r.creditor_iban)

          # Validate amount
          raise CrystalBank::Exception::InvalidArgument.new("Amount must be greater than zero") if r.amount <= 0

          # Validate SEPA currency is EUR
          raise CrystalBank::Exception::InvalidArgument.new("SEPA Credit Transfers must use EUR") unless r.currency == "EUR"

          # Read settlement account from system configuration
          settlement_account_id = CrystalBank::Env.sepa_settlement_account_id

          # Validate both accounts exist, are open, and support EUR
          account_ids = [r.debtor_account_id, settlement_account_id].uniq
          found_accounts = Accounts::Queries::Accounts.new.find_all(account_ids)
          found_by_id = found_accounts.to_h { |a| {a.id, a} }

          [r.debtor_account_id, settlement_account_id].each do |account_id|
            account = found_by_id[account_id]?
            raise CrystalBank::Exception::InvalidArgument.new(
              "Account '#{account_id}' is not open"
            ) unless account && account.status == "active"
            raise CrystalBank::Exception::InvalidArgument.new(
              "Account '#{account_id}' does not support EUR"
            ) unless account.currencies.includes?(CrystalBank::Types::Currencies::Supported::EUR)
          end

          # Create the SEPA Credit Transfer aggregate
          event = Payments::Sepa::CreditTransfers::Initiation::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: payment_id,
            command_handler: self.class.to_s,
            end_to_end_id: end_to_end_id,
            debtor_account_id: r.debtor_account_id,
            creditor_iban: r.creditor_iban,
            creditor_name: r.creditor_name,
            creditor_bic: r.creditor_bic,
            amount: r.amount,
            execution_date: execution_date,
            remittance_information: r.remittance_information,
            scope_id: command.scope_id,
          )

          @event_store.append(event)

          # Build approval subject snapshot for the approver's benefit
          debtor_name = found_by_id[r.debtor_account_id]?.try(&.name) || r.debtor_account_id.to_s
          amount_formatted = "%.2f EUR" % (r.amount / 100.0)
          approval_subject = Approvals::ApprovalSubject.new(
            title: "SEPA Credit Transfer",
            summary: "#{amount_formatted} → #{r.creditor_iban} (#{r.creditor_name})",
            fields: [
              Approvals::ApprovalSubject::Field.new("Amount", amount_formatted),
              Approvals::ApprovalSubject::Field.new("Creditor Name", r.creditor_name),
              Approvals::ApprovalSubject::Field.new("Creditor IBAN", r.creditor_iban),
              Approvals::ApprovalSubject::Field.new("Reference", r.remittance_information),
              Approvals::ApprovalSubject::Field.new("Debtor Account", debtor_name),
            ] of Approvals::ApprovalSubject::Field
          )

          # Create the approval workflow, referencing the payment aggregate
          approval_id = UUID.v7
          Approvals::Creation::Commands::RequestHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Approvals::Creation::Commands::Request.new(
              aggregate_id: approval_id,
              source_aggregate_type: "SepaCreditTransfer",
              source_aggregate_id: payment_id,
              scope_id: command.scope_id,
              required_approvals: ["write_payments_sepa_credit_transfers_approval"],
              actor_id: command.actor_id,
              subject: approval_subject,
            )
          )

          {payment_id: payment_id, approval_id: approval_id}
        end
      end
    end
  end
end
