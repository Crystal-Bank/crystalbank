module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Initiation
    module Commands
      struct Accept < ES::Command
      end

      class AcceptHandler < ES::CommandHandler(Accept)
        def handle(command : Accept)
          payment_id = command.aggregate_id

          # Hydrate the SEPA Credit Transfer aggregate
          payment = Payments::Sepa::CreditTransfers::Aggregate.new(payment_id, event_store: @event_store, event_handlers: @event_handlers)
          payment.hydrate

          # Guard: only accept once
          return if payment.state.status == "accepted"

          amount = payment.state.amount.as(Int64)
          debtor_account_id = payment.state.debtor_account_id.as(UUID)
          settlement_account_id = CrystalBank::Env.sepa_settlement_account_id
          scope_id = payment.state.scope_id.as(UUID)
          execution_date = payment.state.execution_date.as(Time)
          remittance_information = payment.state.remittance_information.to_s
          end_to_end_id = payment.state.end_to_end_id.to_s

          # Re-validate account status at execution time — an account may have been
          # closed or entered closure_pending between request and approval.
          account_ids = [debtor_account_id, settlement_account_id].uniq
          found_accounts = Accounts::Queries::Accounts.new.find_all(account_ids).to_h { |a| {a.id, a} }
          account_ids.each do |account_id|
            account = found_accounts[account_id]?
            return unless account && account.status == "active"
          end

          # Build two balanced ledger entries:
          #   Debit  the debtor's account  (funds leave customer)
          #   Credit the settlement nostro  (funds arrive at SEPA clearing)
          entries_data = [
            Ledger::Transactions::Aggregate::Entry.new(
              id: UUID.v7,
              account_id: debtor_account_id,
              direction: CrystalBank::Types::LedgerTransactions::Direction::DEBIT.to_s,
              amount: amount,
              entry_type: CrystalBank::Types::LedgerTransactions::EntryType::SEPA_CREDIT_TRANSFER.to_s,
            ),
            Ledger::Transactions::Aggregate::Entry.new(
              id: UUID.v7,
              account_id: settlement_account_id,
              direction: CrystalBank::Types::LedgerTransactions::Direction::CREDIT.to_s,
              amount: amount,
              entry_type: CrystalBank::Types::LedgerTransactions::EntryType::SEPA_CREDIT_TRANSFER.to_s,
            ),
          ]
          entries_json = entries_data.to_json

          # Emit the ledger Requested event directly (bypasses DTO validation layer,
          # which requires an API context we do not have here)
          ledger_transaction_id = UUID.v7
          ledger_event = Ledger::Transactions::Request::Events::Requested.new(
            actor_id: nil,
            aggregate_id: ledger_transaction_id,
            command_handler: self.class.to_s,
            currency: CrystalBank::Types::Currencies::Supported::EUR,
            entries_json: entries_json,
            posting_date: execution_date,
            value_date: execution_date,
            remittance_information: remittance_information,
            payment_type: nil,
            external_ref: end_to_end_id,
            channel: nil,
            scope_id: scope_id,
          )

          @event_store.append(ledger_event)

          # Mark the SEPA CT as accepted
          accepted_event = Payments::Sepa::CreditTransfers::Initiation::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: payment_id,
            aggregate_version: payment.state.next_version,
            command_handler: self.class.to_s,
            ledger_transaction_id: ledger_transaction_id,
          )

          @event_store.append(accepted_event)
        end
      end
    end
  end
end
