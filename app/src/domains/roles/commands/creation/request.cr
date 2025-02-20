module CrystalBank::Domains::Roles
  module Creation
    module Commands
      class Request < ES::Command
        def call(r : Roles::Api::Requests::CreationRequest) : UUID
          # TODO: Replace with actor from context
          dummy_actor = UUID.new("00000000-0000-0000-0000-000000000000")
          permissions = r.permissions
          scopes = r.scopes

          # Create the role creation request event
          event = Roles::Creation::Events::Requested.new(
            actor_id: dummy_actor,
            command_handler: self.class.to_s,
            name: r.name,
            permissions: permissions,
            scopes: scopes
          )

          # Append event to event store
          @event_store.append(event)

          # Return the aggregate ID of the newly created role aggregate
          UUID.new(event.header.aggregate_id.to_s)
        end
      end
    end
  end
end
