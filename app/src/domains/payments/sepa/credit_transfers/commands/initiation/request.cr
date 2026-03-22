module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Initiation
    module Commands
      class Request < ES::Command
        def call(
          r : Payments::Sepa::CreditTransfers::Api::Requests::CreditTransferRequest,
          c : CrystalBank::Api::Context,
        ) : {payment_id: UUID, approval_id: UUID}
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

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

          # Validate amount
          raise CrystalBank::Exception::InvalidArgument.new("Amount must be greater than zero") if r.amount <= 0

          # Validate SEPA currency is EUR
          raise CrystalBank::Exception::InvalidArgument.new("SEPA Credit Transfers must use EUR") unless r.currency == "EUR"

          # Validate IBAN structural validity and MOD-97 checksum (ISO 13616)
          raise CrystalBank::Exception::InvalidArgument.new(
            "Invalid IBAN '#{r.creditor_iban}': failed structural or checksum validation"
          ) unless CrystalBank::Validators::Iban.valid?(r.creditor_iban)

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
            ) unless account
            raise CrystalBank::Exception::InvalidArgument.new(
              "Account '#{account_id}' does not support EUR"
            ) unless account.currencies.includes?(CrystalBank::Types::Currencies::Supported::EUR)
          end

          # Create the SEPA Credit Transfer aggregate
          event = Payments::Sepa::CreditTransfers::Initiation::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            end_to_end_id: end_to_end_id,
            debtor_account_id: r.debtor_account_id,
            creditor_iban: r.creditor_iban,
            creditor_name: r.creditor_name,
            creditor_bic: r.creditor_bic,
            amount: r.amount,
            execution_date: execution_date,
            remittance_information: r.remittance_information,
            scope_id: scope,
          )

          @event_store.append(event)

          payment_id = UUID.new(event.header.aggregate_id.to_s)

          # Create the approval workflow, referencing the payment aggregate
          approval_id = Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "SepaCreditTransfer",
            source_aggregate_id: payment_id,
            scope_id: scope,
            required_approvals: ["write_payments_sepa_credit_transfers_approval"],
            actor_id: actor,
          )

          {payment_id: payment_id, approval_id: approval_id}
        end
      end
    end
  end
end
