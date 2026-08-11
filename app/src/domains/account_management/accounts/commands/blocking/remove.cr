module CrystalBank::Domains::Accounts
  module Blocking
    module Commands
      struct Remove < ES::Command
        getter requestor_id : UUID?

        def initialize(@aggregate_id : UUID, @requestor_id)
        end
      end

      # Triggered when an approval for an AccountUnblock request is completed.
      # Hydrates the unblocking request aggregate to recover the intent and removes
      # the block from the account aggregate.
      class RemoveHandler < ES::CommandHandler(Remove)
        def handle(command : Remove)
          unblock_request_id = command.aggregate_id

          unblock_request = ::Accounts::Blocking::Unblocking::Aggregate.new(unblock_request_id, event_store: @event_store, event_handlers: @event_handlers)
          unblock_request.hydrate

          return if unblock_request.state.completed

          account_id = unblock_request.state.account_id.as(UUID)
          block_type = unblock_request.state.block_type.as(CrystalBank::Types::Accounts::BlockType)
          reason = unblock_request.state.reason

          account = ::Accounts::Aggregate.new(account_id, event_store: @event_store, event_handlers: @event_handlers)
          account.hydrate

          removed_event = ::Accounts::Blocking::Events::Removed.new(
            aggregate_id: account_id,
            aggregate_version: account.state.next_version,
            actor_id: command.requestor_id,
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
