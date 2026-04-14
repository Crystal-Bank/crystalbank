module CrystalBank::Domains::Roles
  module PermissionsUpdate
    module Commands
      class Request < ES::Command
        def call(r : Roles::Api::Requests::PermissionsUpdateRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          # Hydrate the role aggregate — this is our consistency boundary.
          # Appending the Requested event at next_version serialises concurrent
          # requests via the event store's unique (aggregate_id, version) constraint.
          role = Roles::Aggregate.new(r.role_id)
          begin
            role.hydrate
          rescue ES::Exception::NotFound
            raise CrystalBank::Exception::InvalidArgument.new("Role '#{r.role_id}' not found")
          end

          raise CrystalBank::Exception::InvalidArgument.new("Role '#{r.role_id}' is not active") unless role.state.status == "active"

          # Guard: only one permissions update may be in flight at a time
          if role.state.has_pending_permissions_update
            raise CrystalBank::Exception::InvalidArgument.new("Role '#{r.role_id}' already has a pending permissions update")
          end

          # Guard against no-op updates
          if r.permissions.sort_by(&.to_s) == role.state.permissions.as(Array(CrystalBank::Permissions)).sort_by(&.to_s)
            raise CrystalBank::Exception::InvalidArgument.new("Permissions are unchanged — the submitted list is identical to the role's current permissions")
          end

          # Append Requested directly onto the Role aggregate.
          # The event store's unique constraint on (aggregate_id, aggregate_version)
          # rejects any truly concurrent request that races past the guard above.
          event = Roles::PermissionsUpdate::Events::Requested.new(
            actor_id: actor,
            aggregate_id: r.role_id,
            aggregate_version: role.state.next_version,
            command_handler: self.class.to_s,
            permissions: r.permissions
          )
          @event_store.append(event)

          r.role_id
        end
      end
    end
  end
end
