module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Initiation
    module Commands
      class Request < ES::Command
        def call(
          r : Payments::Sepa::CreditTransfers::Api::Requests::CreditTransferRequest,
          c : CrystalBank::Api::Context,
        ) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          # Validate execution date format
          execution_date = Time.utc
          begin
            execution_date = Time::Format::ISO_8601_DATE.parse(r.execution_date)
          rescue
            raise CrystalBank::Exception::InvalidArgument.new("Invalid execution_date format, expected YYYY-MM-DD")
          end

          # Validate amount
          raise CrystalBank::Exception::InvalidArgument.new("Amount must be greater than zero") if r.amount <= 0

          # Validate SEPA currency is EUR
          raise CrystalBank::Exception::InvalidArgument.new("SEPA Credit Transfers must use EUR") unless r.currency == "EUR"

          # Validate both accounts exist, are open, and support EUR
          account_ids = [r.debtor_account_id, r.settlement_account_id].uniq
          found_accounts = Accounts::Queries::Accounts.new.find_all(account_ids)
          found_by_id = found_accounts.to_h { |a| {a.id, a} }

          [r.debtor_account_id, r.settlement_account_id].each do |account_id|
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
            end_to_end_id: r.end_to_end_id,
            debtor_account_id: r.debtor_account_id,
            settlement_account_id: r.settlement_account_id,
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
          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "SepaCreditTransfer",
            source_aggregate_id: payment_id,
            scope_id: scope,
            required_approvals: ["write_payments_sepa_credit_transfers_approval"],
            actor_id: actor,
          )

          payment_id
        end
      end
    end
  end
end
