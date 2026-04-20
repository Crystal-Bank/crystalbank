module CrystalBank::Domains::Roles
  module PermissionsUpdate
    module Commands
      class Request < ES::Command
        def call(r : Roles::Api::Requests::PermissionsUpdateRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          # Validate the role exists and is active
          role = Roles::Queries::Roles.new.find!(r.role_id)
          raise CrystalBank::Exception::InvalidArgument.new("Role '#{r.role_id}' is not active") unless role.status == "active"

          # Pending guard: at most one update request may be in flight per role.
          # This is a soft guard via the projection; the event store constraint is the hard backstop.
          has_pending = ES::Config.projection_database.query_one(
            %(SELECT EXISTS (SELECT 1 FROM "projections"."roles_permissions_updates" WHERE role_id = $1 AND status = 'pending_approval')),
            r.role_id,
            as: Bool
          )
          if has_pending
            raise CrystalBank::Exception::InvalidArgument.new("Role '#{r.role_id}' already has a pending permissions update")
          end

          # Guard against no-op updates
          if r.permissions.sort_by(&.to_s) == role.permissions.sort_by(&.to_s)
            raise CrystalBank::Exception::InvalidArgument.new("Permissions are unchanged — the submitted list is identical to the role's current permissions")
          end

          # Create the permissions update request event on a new aggregate
          event = Roles::PermissionsUpdate::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            role_id: r.role_id,
            permissions: r.permissions
          )
          @event_store.append(event)

          update_request_id = UUID.new(event.header.aggregate_id.to_s)

          # Create the approval workflow inline (same pattern as account blocking)
          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "RolePermissionsUpdate",
            source_aggregate_id: update_request_id,
            scope_id: scope,
            required_approvals: ["write_roles_permissions_update_approval"],
            actor_id: actor
          )

          update_request_id
        end
      end
    end
  end
end
