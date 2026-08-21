module CrystalBank::Domains::Accounts
  module Closure
    module Commands
      struct Accept < ES::Command
      end

      class AcceptHandler < ES::CommandHandler(Accept)
        def handle(command : Accept)
          closure_request_id = command.aggregate_id

          closure_request = ::Accounts::ClosureRequest::Aggregate.new(closure_request_id, event_store: @event_store, event_handlers: @event_handlers)
          closure_request.hydrate

          return if closure_request.state.completed

          account_id = closure_request.state.account_id.as(UUID)

          account = ::Accounts::Aggregate.new(account_id, event_store: @event_store, event_handlers: @event_handlers)
          account.hydrate

          accepted_event = ::Accounts::Closure::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: account_id,
            aggregate_version: account.state.next_version,
            command_handler: self.class.to_s
          )
          @event_store.append(accepted_event)

          completed_event = ::Accounts::ClosureRequest::Events::Completed.new(
            actor_id: nil,
            aggregate_id: closure_request_id,
            aggregate_version: closure_request.state.next_version,
            command_handler: self.class.to_s
          )
          @event_store.append(completed_event)
        end
      end
    end
  end
end
