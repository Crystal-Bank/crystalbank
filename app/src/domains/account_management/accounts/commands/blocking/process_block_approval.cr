module CrystalBank::Domains::Accounts
  module Blocking
    module Commands
      # Triggered when an approval for an AccountBlock request is completed.
      # Hydrates the blocking request aggregate to recover the intent and applies
      # the block to the account aggregate.
      class ProcessBlockApproval < ES::Command
        def call
          approval = Approvals::Aggregate.new(@aggregate_id.as(UUID))
          approval.hydrate

          return unless approval.state.source_aggregate_type == "AccountBlock"

          block_request_id = approval.state.source_aggregate_id.as(UUID)

          block_request = ::Accounts::Blocking::Blocking::Aggregate.new(block_request_id)
          block_request.hydrate

          return if block_request.state.completed

          account_id = block_request.state.account_id.as(UUID)
          block_type = block_request.state.block_type.as(CrystalBank::Types::Accounts::BlockType)
          reason = block_request.state.reason

          account = ::Accounts::Aggregate.new(account_id)
          account.hydrate

          applied_event = ::Accounts::Blocking::Events::Applied.new(
            aggregate_id: account_id,
            aggregate_version: account.state.next_version,
            actor_id: approval.state.requestor_id,
            command_handler: self.class.to_s,
            block_type: block_type,
            reason: reason
          )
          @event_store.append(applied_event)

          completed_event = ::Accounts::Blocking::Blocking::Events::Completed.new(
            actor_id: nil,
            aggregate_id: block_request_id,
            aggregate_version: block_request.state.next_version,
            command_handler: self.class.to_s
          )
          @event_store.append(completed_event)
        end
      end
    end
  end
end
