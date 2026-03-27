module CrystalBank::Domains::Accounts
  module Blocking
    module Commands
      # Triggered when an approval for an AccountUnblock request is completed.
      # Hydrates the unblocking request aggregate to recover the intent and removes
      # the block from the account aggregate.
      class ProcessUnblockApproval < ES::Command
        def call
          approval = Approvals::Aggregate.new(@aggregate_id.as(UUID))
          approval.hydrate

          return unless approval.state.source_aggregate_type == "AccountUnblock"

          unblock_request_id = approval.state.source_aggregate_id.as(UUID)

          unblock_request = ::Accounts::Blocking::Unblocking::Aggregate.new(unblock_request_id)
          unblock_request.hydrate

          return if unblock_request.state.completed

          account_id = unblock_request.state.account_id.as(UUID)
          block_type = unblock_request.state.block_type.as(CrystalBank::Types::Accounts::BlockType)
          reason = unblock_request.state.reason

          account = ::Accounts::Aggregate.new(account_id)
          account.hydrate

          removed_event = ::Accounts::Blocking::Events::Removed.new(
            aggregate_id: account_id,
            aggregate_version: account.state.next_version,
            actor_id: approval.state.requestor_id,
            command_handler: self.class.to_s,
            block_type: block_type,
            reason: reason
          )
          @event_store.append(removed_event)

          completed_event = ::Accounts::Blocking::Unblocking::Events::Completed.new(
            actor_id: nil,
            aggregate_id: unblock_request_id,
            aggregate_version: unblock_request.state.next_version,
            command_handler: self.class.to_s
          )
          @event_store.append(completed_event)
        end
      end
    end
  end
end
