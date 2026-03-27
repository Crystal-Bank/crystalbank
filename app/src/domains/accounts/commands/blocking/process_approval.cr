module CrystalBank::Domains::Accounts
  module Blocking
    module Commands
      # Triggered when an approval for an AccountBlockRequest is completed.
      # Reads the block request aggregate to recover the intent (account_id,
      # block_type, action) and then executes the actual block or unblock on the
      # account aggregate.
      class ProcessApproval < ES::Command
        def call
          approval_aggregate_id = @aggregate_id.as(UUID)

          # Hydrate the approval aggregate to get source info
          approval = Approvals::Aggregate.new(approval_aggregate_id)
          approval.hydrate

          # Only process approvals that reference an AccountBlockRequest
          return unless approval.state.source_aggregate_type == "AccountBlockRequest"

          block_request_id = approval.state.source_aggregate_id.as(UUID)

          # Hydrate the block request aggregate to recover the intent
          block_request = ::Accounts::Blocking::Aggregate.new(block_request_id)
          block_request.hydrate

          # Guard: only process once
          return if block_request.state.completed

          account_id = block_request.state.account_id.as(UUID)
          block_type = block_request.state.block_type.as(CrystalBank::Types::Accounts::BlockType)
          action = block_request.state.action.as(String)
          reason = block_request.state.reason

          # Hydrate the account aggregate to get current version
          account = ::Accounts::Aggregate.new(account_id)
          account.hydrate

          next_account_version = account.state.next_version

          case action
          when "apply"
            event = ::Accounts::Blocking::Events::Applied.new(
              aggregate_id: account_id,
              aggregate_version: next_account_version,
              actor_id: nil,
              command_handler: self.class.to_s,
              block_type: block_type,
              reason: reason
            )
            @event_store.append(event)
          when "remove"
            event = ::Accounts::Blocking::Events::Removed.new(
              aggregate_id: account_id,
              aggregate_version: next_account_version,
              actor_id: nil,
              command_handler: self.class.to_s,
              block_type: block_type,
              reason: reason
            )
            @event_store.append(event)
          end

          # Mark the block request as completed
          next_br_version = block_request.state.next_version

          completed_event = ::Accounts::Blocking::BlockRequest::Events::Completed.new(
            actor_id: nil,
            aggregate_id: block_request_id,
            aggregate_version: next_br_version,
            command_handler: self.class.to_s
          )

          @event_store.append(completed_event)
        end
      end
    end
  end
end
