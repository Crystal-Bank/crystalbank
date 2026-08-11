module CrystalBank::Domains::Roles
  module PermissionsUpdate
    module Commands
      struct Request < ES::Command
        getter role_id : UUID
        getter permissions : Array(CrystalBank::Permissions)
        getter actor_id : UUID
        getter scope_id : UUID

        def initialize(@aggregate_id : UUID, @role_id, @permissions, @actor_id, @scope_id)
        end
      end

      class RequestHandler < ES::CommandHandler(Request)
        def handle(command : Request)
          # Validate the role exists and is active
          role = Roles::Queries::Roles.new.find!(command.role_id)
          raise CrystalBank::Exception::InvalidArgument.new("Role '#{command.role_id}' is not active") unless role.status == "active"

          # Pending guard: at most one update request may be in flight per role.
          # This is a soft guard via the projection; the event store constraint is the hard backstop.
          has_pending = ES::Config.projection_database.query_one(
            %(SELECT EXISTS (SELECT 1 FROM "projections"."roles_permissions_updates" WHERE role_id = $1 AND status = 'pending_approval')),
            command.role_id,
            as: Bool
          )
          if has_pending
            raise CrystalBank::Exception::InvalidArgument.new("Role '#{command.role_id}' already has a pending permissions update")
          end

          # Guard against no-op updates
          if command.permissions.sort_by(&.to_s) == role.permissions.sort_by(&.to_s)
            raise CrystalBank::Exception::InvalidArgument.new("Permissions are unchanged — the submitted list is identical to the role's current permissions")
          end

          update_request_id = command.aggregate_id

          # Create the permissions update request event on a new aggregate
          event = Roles::PermissionsUpdate::Events::Requested.new(
            actor_id: command.actor_id,
            aggregate_id: update_request_id,
            command_handler: self.class.to_s,
            role_id: command.role_id,
            permissions: command.permissions
          )
          @event_store.append(event)

          permission_count = command.permissions.size.to_s
          approval_subject = Approvals::ApprovalSubject.new(
            title: "Role Permissions Update",
            summary: "#{role.name}: #{permission_count} permissions",
            fields: [
              Approvals::ApprovalSubject::Field.new("Role", role.name),
              Approvals::ApprovalSubject::Field.new("Permissions", permission_count),
            ] of Approvals::ApprovalSubject::Field
          )

          approval_id = UUID.v7
          Approvals::Creation::Commands::RequestHandler.new(event_store: @event_store, event_handlers: @event_handlers).handle(
            Approvals::Creation::Commands::Request.new(
              aggregate_id: approval_id,
              source_aggregate_type: "RolePermissionsUpdate",
              source_aggregate_id: update_request_id,
              scope_id: command.scope_id,
              required_approvals: ["write_roles_permissions_update_approval"],
              actor_id: command.actor_id,
              subject: approval_subject,
            )
          )

          {update_request_id: update_request_id, approval_id: approval_id}
        end
      end
    end
  end
end
