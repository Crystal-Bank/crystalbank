module CrystalBank::Domains::ApiKeys
  module Revocation
    module Commands
      struct Request < ES::Command
        getter reason : String
        getter actor_id : UUID

        def initialize(@aggregate_id : UUID, @reason, @actor_id)
        end
      end

      class RequestHandler < ES::CommandHandler(Request)
        def handle(command : Request) : Bool
          # Build the aggregate
          aggregate = ApiKeys::Aggregate.new(command.aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
          aggregate.hydrate

          # Extract attributes to local variables
          next_version = aggregate.state.next_version
          aggregate_id = aggregate.state.aggregate_id
          scope_id = aggregate.state.scope_id

          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope_id

          # Raise exception if api key is not active
          raise CrystalBank::Exception::InvalidArgument.new("ApiKey '#{aggregate_id}' is in a non-active state and cannot be revoked") unless aggregate.state.status == "active"

          # Create the revocation request
          event = ApiKeys::Revocation::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: aggregate_id,
            aggregate_version: next_version,
            command_handler: self.class.to_s,
            scope_id: scope_id,
            reason: command.reason
          )

          # Append event to event store
          @event_store.append(event)

          true
        end
      end
    end
  end
end
