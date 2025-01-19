module CrystalBank::Domains::Scopes
  module Creation
    module Commands
      class ProcessRequest < ES::Command
        def call
          aggregate_id = @aggregate_id.as(UUID)
          # TODO: Run checks to check the legitimacy of the scope creation

          # Build the scope aggregate
          aggregate = Scopes::Aggregate.new(aggregate_id)
          aggregate.hydrate

          # Calculate the next aggregate version
          next_version = aggregate.state.next_version

          # Create the scope creation acceptance event
          event = Scopes::Creation::Events::Accepted.new(
            actor_id: nil,
            aggregate_id: aggregate_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s
          )

          # Append event to event store
          @event_store.append(event)
        end
      end
    end
  end
end
