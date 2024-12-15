module CrystalBank::Domains::ApiKeys
  module Revocation
    module Commands
      class Request < ES::Command
        def call(api_key_id : UUID, r : ApiKeys::Api::Requests::RevocationRequest) : Bool
          # TODO: Replace with actor from context
          dummy_actor = UUID.new("00000000-0000-0000-0000-000000000000")

          # Build the aggregate
          aggregate = ApiKeys::Aggregate.new(api_key_id)
          aggregate.hydrate

          # Extract attributes to local variables
          next_version = aggregate.state.next_version
          aggregate_id = aggregate.state.aggregate_id
          aggregate_type = aggregate.state.aggregate_type

          # Raise exception if api key is not active
          raise CrystalBank::Exception::InvalidArgument.new("ApiKey '#{aggregate_id}' is in a non-active state and cannot be revoked") unless aggregate.state.active

          # Create the revocation request
          event = ApiKeys::Revocation::Events::Requested.new(
            actor_id: dummy_actor,
            aggregate_id: aggregate_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s,
            reason: r.reason
          )

          # Append event to event store
          @event_store.append(event)

          true
        end
      end
    end
  end
end
