module CrystalBank::Domains::Roles
  module Creation
    module Commands
      class Request < ES::Command
        def call(r : Roles::Api::Requests::CreationRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          permissions = r.permissions
          scopes = r.scopes

          # Validate that all provided scope IDs exist and are active
          unless scopes.empty?
            active_scope_ids = Scopes::Queries::Scopes.new.find_active(scopes)
            invalid_scopes = scopes - active_scope_ids
            unless invalid_scopes.empty?
              raise CrystalBank::Exception::InvalidArgument.new(
                "Invalid or inactive scopes: #{invalid_scopes.map(&.to_s).join(", ")}"
              )
            end
          end

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
