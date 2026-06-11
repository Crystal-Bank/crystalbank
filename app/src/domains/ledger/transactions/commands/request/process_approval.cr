module CrystalBank::Domains::Ledger::Transactions
  module Request
    module Commands
      class ProcessApproval < ES::Command
        def call
          approval_aggregate_id = @aggregate_id.as(UUID)

          # Hydrate the approval aggregate to get source info
          approval = Approvals::Aggregate.new(approval_aggregate_id)
          approval.hydrate

          # Only process if this approval is for a LedgerTransaction
          return unless approval.state.source_aggregate_type == "LedgerTransaction"

          transaction_id = approval.state.source_aggregate_id.as(UUID)

          # Hydrate the ledger transaction aggregate
          transaction = Ledger::Transactions::Aggregate.new(transaction_id)
          transaction.hydrate

          # Guard: only accept once
          return if transaction.state.status == "accepted"

          next_version = transaction.state.next_version

          event = Ledger::Transactions::Request::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: transaction_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s,
          )

          @event_store.append(event)
        end
      end
    end
  end
end
