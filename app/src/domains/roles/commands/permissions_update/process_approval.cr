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

          update_request_id = approval.state.source_aggregate_id.as(UUID)

          # Hydrate the permissions update request aggregate
          update_request = Roles::PermissionsUpdate::Aggregate.new(update_request_id)
          update_request.hydrate

          # Guard against double-processing
          return if update_request.state.completed

          role_id = update_request.state.role_id.as(UUID)
          permissions = update_request.state.permissions.as(Array(CrystalBank::Permissions))

          # Hydrate the role aggregate to get the next version
          role = Roles::Aggregate.new(role_id)
          role.hydrate

          # Apply the approved permissions onto the Role aggregate
          accepted_event = Roles::PermissionsUpdate::Events::Accepted.new(
            actor_id: approval.state.requestor_id,
            aggregate_id: role_id,
            aggregate_version: role.state.next_version,
            command_handler: self.class.to_s,
            permissions: permissions
          )
          @event_store.append(accepted_event)

          # Mark the update request itself as completed
          completed_event = Roles::PermissionsUpdate::Events::Completed.new(
            actor_id: nil,
            aggregate_id: update_request_id,
            aggregate_version: update_request.state.next_version,
            command_handler: self.class.to_s
          )
          @event_store.append(completed_event)
        end
      end
    end
  end
end
