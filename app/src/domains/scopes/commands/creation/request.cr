module CrystalBank::Domains::Scopes
  module Creation
    module Commands
      class Request < ES::Command
        def call(r : Scopes::Api::Requests::CreationRequest) : UUID
          # TODO: Replace with actor from context
          dummy_actor = UUID.new("00000000-0000-0000-0000-000000000000")
          parent_scope_id = r.parent_scope_id

          # Check if provided parent scope can be found
          unless parent_scope_id.nil?
            aggregate = Scopes::Aggregate.new(parent_scope_id)
            aggregate.hydrate
          end

          # Create the scope creation request event
          event = Scopes::Creation::Events::Requested.new(
            actor_id: dummy_actor,
            command_handler: self.class.to_s,
            name: r.name,
            parent_scope_id: parent_scope_id
          )

          # Append event to event store
          @event_store.append(event)

          # Return the aggregate ID of the newly created scope aggregate
          UUID.new(event.header.aggregate_id.to_s)
        end
      end
    end
  end
end
