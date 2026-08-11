module CrystalBank::Domains::Scopes
  module Creation
    module Commands
      struct Accept < ES::Command
      end

      class AcceptHandler < ES::CommandHandler(Accept)
        def handle(command : Accept)
          # Build the scope aggregate
          scope = Scopes::Aggregate.new(command.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          scope.hydrate

          # Create the scope creation acceptance event
          event = Scopes::Creation::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: command.aggregate_id,
            aggregate_version: scope.state.next_version,
            command_handler: self.class.to_s
          )

          # Append event to event store
          @event_store.append(event)
        end
      end
    end
  end
end
