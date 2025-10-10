module CrystalBank::Domains::Users
  module AssignRoles
    module Commands
      class ProcessRequest < ES::Command
        def call
          aggregate_id = @aggregate_id.as(UUID)
          # TODO: Run checks to check the availability of the roles provided to the context

          # Build the user aggregate
          aggregate = Users::Aggregate.new(aggregate_id)
          aggregate.hydrate

          # Calculate the next aggregate version
          next_version = aggregate.state.next_version

          # Create the account creation acceptance event
          event = Users::AssignRoles::Events::Accepted.new(
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
