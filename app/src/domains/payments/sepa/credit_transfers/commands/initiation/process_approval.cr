module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Initiation
    module Commands
      class ProcessApproval < ES::Command
        def call
          approval_aggregate_id = @aggregate_id.as(UUID)

          # Hydrate the approval aggregate to get source info
          approval = Approvals::Aggregate.new(approval_aggregate_id)
          approval.hydrate

          # Only process if this approval is for a SEPA Credit Transfer
          return unless approval.state.source_aggregate_type == "SepaCreditTransfer"

          payment_id = approval.state.source_aggregate_id.as(UUID)

          # Hydrate the SEPA Credit Transfer aggregate
          payment = Payments::Sepa::CreditTransfers::Aggregate.new(payment_id)
          payment.hydrate

          # Guard: only accept once
          return if payment.state.status == "accepted"

          amount = payment.state.amount.as(Int64)
          debtor_account_id = payment.state.debtor_account_id.as(UUID)
          settlement_account_id = UUID.new(ENV["SEPA_SETTLEMENT_ACCOUNT_ID"])
          scope_id = payment.state.scope_id.as(UUID)
          execution_date = payment.state.execution_date.as(Time)
          remittance_information = payment.state.remittance_information.to_s
          end_to_end_id = payment.state.end_to_end_id.to_s

          # Build two balanced ledger entries:
          #   Debit  the debtor's account  (funds leave customer)
          #   Credit the settlement nostro  (funds arrive at SEPA clearing)
          entries_data = [
            Ledger::Transactions::Aggregate::Entry.new(
              id: UUID.v7,
              account_id: debtor_account_id,
              direction: "DEBIT",
              amount: amount,
              entry_type: "PRINCIPAL",
            ),
            Ledger::Transactions::Aggregate::Entry.new(
              id: UUID.v7,
              account_id: settlement_account_id,
              direction: "CREDIT",
              amount: amount,
              entry_type: "SETTLEMENT",
            ),
          ]
          entries_json = entries_data.to_json

          # Emit the ledger Requested event directly (bypasses DTO validation layer,
          # which requires an API context we do not have here)
          ledger_event = Ledger::Transactions::Request::Events::Requested.new(
            actor_id: nil,
            command_handler: self.class.to_s,
            currency: CrystalBank::Types::Currencies::Supported::EUR,
            entries_json: entries_json,
            posting_date: execution_date,
            value_date: execution_date,
            remittance_information: remittance_information,
            payment_type: "SEPA_CREDIT_TRANSFER",
            external_ref: end_to_end_id,
            channel: "SEPA",
            scope_id: scope_id,
          )

          @event_store.append(ledger_event)

          ledger_transaction_id = UUID.new(ledger_event.header.aggregate_id.to_s)

          # Mark the SEPA CT as accepted
          next_version = payment.state.next_version

          accepted_event = Payments::Sepa::CreditTransfers::Initiation::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: payment_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s,
            ledger_transaction_id: ledger_transaction_id,
          )

          @event_store.append(accepted_event)
        end
      end
    end
  end
end
