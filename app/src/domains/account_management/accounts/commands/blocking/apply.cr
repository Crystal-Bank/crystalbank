module CrystalBank::Domains::Accounts
  module Blocking
    module Commands
      struct Apply < ES::Command
        getter requestor_id : UUID?

        def initialize(@aggregate_id : UUID, @requestor_id)
        end
      end

      # Triggered when an approval for an AccountBlock request is completed.
      # Hydrates the blocking request aggregate to recover the intent and applies
      # the block to the account aggregate.
      class ApplyHandler < ES::CommandHandler(Apply)
        def handle(command : Apply)
          block_request_id = command.aggregate_id

          block_request = ::Accounts::BlockingRequest::Aggregate.new(block_request_id, event_store: @event_store, event_handlers: @event_handlers)
          block_request.hydrate

          return if block_request.state.completed

          account_id = block_request.state.account_id.as(UUID)
          block_type = block_request.state.block_type.as(CrystalBank::Types::Accounts::BlockType)
          reason = block_request.state.reason

          account = ::Accounts::Aggregate.new(account_id, event_store: @event_store, event_handlers: @event_handlers)
          account.hydrate

          applied_event = ::Accounts::Blocking::Events::Applied.new(
            aggregate_id: account_id,
            aggregate_version: account.state.next_version,
            actor_id: command.requestor_id,
            command_handler: self.class.to_s,
            block_type: block_type,
            reason: reason
          )
          @event_store.append(applied_event)

          completed_event = ::Accounts::BlockingRequest::Events::Completed.new(
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
