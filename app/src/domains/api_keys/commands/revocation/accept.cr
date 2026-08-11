module CrystalBank::Domains::ApiKeys
  module Revocation
    module Commands
      struct Accept < ES::Command
      end

      class AcceptHandler < ES::CommandHandler(Accept)
        def handle(command : Accept)
          # Build the api key aggregate
          aggregate = ApiKeys::Aggregate.new(command.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          aggregate.hydrate

          # Create the revocation acceptance event
          event = ApiKeys::Revocation::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: command.aggregate_id,
            aggregate_version: aggregate.state.next_version,
            command_handler: self.class.to_s
          )

          # Append event to event store
          @event_store.append(event)
        end
      end
    end
  end
end
