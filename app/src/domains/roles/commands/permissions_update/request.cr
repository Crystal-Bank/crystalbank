module CrystalBank::Domains::Roles
  module PermissionsUpdate
    module Commands
      class Request < ES::Command
        def call(r : Roles::Api::Requests::PermissionsUpdateRequest, c : CrystalBank::Api::Context) : UUID
          actor = c.user_id
          scope = c.scope
          raise CrystalBank::Exception::InvalidArgument.new("Invalid scope") unless scope

          # Validate that at least one side of the diff is non-empty
          if r.permissions_to_add.empty? && r.permissions_to_remove.empty?
            raise CrystalBank::Exception::InvalidArgument.new("At least one permission must be added or removed")
          end

          # Validate that the same permission does not appear in both lists
          overlap = r.permissions_to_add & r.permissions_to_remove
          unless overlap.empty?
            raise CrystalBank::Exception::InvalidArgument.new("Permissions cannot appear in both permissions_to_add and permissions_to_remove: #{overlap.map(&.to_s).join(", ")}")
          end

          # Validate the role exists and is active
          role = Roles::Queries::FindRole.new.find!(r.role_id)
          raise CrystalBank::Exception::InvalidArgument.new("Role '#{r.role_id}' is not active") unless role.status == "active"

          # Validate that permissions being removed are actually present on the role
          unless r.permissions_to_remove.empty?
            missing = r.permissions_to_remove - role.permissions
            unless missing.empty?
              raise CrystalBank::Exception::InvalidArgument.new("Permissions not present on role and cannot be removed: #{missing.map(&.to_s).join(", ")}")
            end
          end

          # Create the permissions update request event (new aggregate)
          event = Roles::PermissionsUpdate::Events::Requested.new(
            actor_id: actor,
            command_handler: self.class.to_s,
            role_id: r.role_id,
            permissions_to_add: r.permissions_to_add,
            permissions_to_remove: r.permissions_to_remove
          )
          @event_store.append(event)

          update_request_id = UUID.new(event.header.aggregate_id.to_s)

          # Create an approval workflow for this permissions update
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
