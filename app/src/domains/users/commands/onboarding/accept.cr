module CrystalBank::Domains::Users
  module Onboarding
    module Commands
      struct Accept < ES::Command
      end

      class AcceptHandler < ES::CommandHandler(Accept)
        def handle(command : Accept)
          # Build the user aggregate
          user = Users::Aggregate.new(command.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          user.hydrate

          # Create the user onboarding acceptance event
          event = Users::Onboarding::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: command.aggregate_id,
            aggregate_version: user.state.next_version,
            command_handler: self.class.to_s
          )

          # Append event to event store
          @event_store.append(event)
        end
      end
    end
  end
end
