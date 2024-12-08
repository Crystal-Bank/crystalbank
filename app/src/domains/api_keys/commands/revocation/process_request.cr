module CrystalBank::Domains::ApiKeys
  module Revocation
    module Commands
      class ProcessRequest < ES::Command
        def call
          aggregate_id = @aggregate_id.as(UUID)
          # TODO: Run checks to check the legitimacy of the api key revocation

          # Build the account aggregate
          aggregate = ApiKeys::Aggregate.new(aggregate_id)
          aggregate.hydrate

          # Calculate the next aggregate version
          next_version = aggregate.state.next_version

          # Create the account creation acceptance event
          event = ApiKeys::Revocation::Events::Accepted.new(
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
