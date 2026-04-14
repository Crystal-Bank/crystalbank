module CrystalBank::Domains::Roles
  module PermissionsUpdate
    module Commands
      class ProcessApproval < ES::Command
        def call
          approval_aggregate_id = @aggregate_id.as(UUID)

          # Hydrate the approval aggregate to get source info
          approval = Approvals::Aggregate.new(approval_aggregate_id)
          approval.hydrate

          # Only process if this approval is for a RolePermissionsUpdate
          return unless approval.state.source_aggregate_type == "RolePermissionsUpdate"

          # source_aggregate_id IS the Role aggregate — no separate aggregate to hydrate
          role_id = approval.state.source_aggregate_id.as(UUID)

          role = Roles::Aggregate.new(role_id)
          role.hydrate

          # The pending permissions were recorded on the Role aggregate when Requested was appended
          permissions = role.state.pending_permissions.as(Array(CrystalBank::Permissions))

          accepted_event = Roles::PermissionsUpdate::Events::Accepted.new(
            actor_id: approval.state.requestor_id,
            aggregate_id: role_id,
            aggregate_version: role.state.next_version,
            command_handler: self.class.to_s,
            permissions: permissions
          )
          @event_store.append(accepted_event)
        end
      end
    end
  end
end
