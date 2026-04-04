module CrystalBank::Domains::ApiKeys
  module Revocation
    module Commands
      class Request < ES::Command
        def call(api_key_id : UUID, r : ApiKeys::Api::Requests::RevocationRequest, c : CrystalBank::Api::Context) : Bool
          actor = c.user_id

          # Build the aggregate
          aggregate = ApiKeys::Aggregate.new(api_key_id)
          aggregate.hydrate

          # Extract attributes to local variables
          next_version = aggregate.state.next_version
          aggregate_id = aggregate.state.aggregate_id
          aggregate_type = aggregate.state.aggregate_type
          scope_id = aggregate.state.scope_id

          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope_id

          # Raise exception if api key is not active
          raise CrystalBank::Exception::InvalidArgument.new("ApiKey '#{aggregate_id}' is in a non-active state and cannot be revoked") unless aggregate.state.status == "active"

          # Create the revocation request
          event = ApiKeys::Revocation::Events::Requested.new(
            actor_id: actor,
            aggregate_id: aggregate_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s,
            scope_id: scope_id,
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
