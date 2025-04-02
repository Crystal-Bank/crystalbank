module CrystalBank::Domains::Roles
  module Creation
    module Commands
      class Request < ES::Command
        def call(r : Roles::Api::Requests::CreationRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          permissions = r.permissions
          # TODO check validity of scopes
          scopes = r.scopes

          # Create the role creation request event
          event = Roles::Creation::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            name: r.name,
            permissions: permissions,
            scope_id: scope,
            scopes: scopes
          )

          scope
          # Append event to event store
          @event_store.append(event)

          # Return the aggregate ID of the newly created role aggregate
          UUID.new(event.header.aggregate_id.to_s)
        end
      end
    end
  end
end
