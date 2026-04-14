module CrystalBank::Domains::Roles
  module Aggregates
    module Concerns
      module PermissionsUpdate
        # Apply 'Roles::PermissionsUpdate::Events::Requested' to the aggregate state.
        # Records the desired permissions and sets the pending flag so the Request
        # command can guard against a second concurrent update on the same role.
        def apply(event : Roles::PermissionsUpdate::Events::Requested)
          @state.increase_version(event.header.aggregate_version)
          body = event.body.as(Roles::PermissionsUpdate::Events::Requested::Body)
          @state.pending_permissions = body.permissions
          @state.has_pending_permissions_update = true
        end

        # Apply 'Roles::PermissionsUpdate::Events::Accepted' to the aggregate state.
        # Replaces the live permissions with the approved set and clears the pending flag.
        def apply(event : Roles::PermissionsUpdate::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)
          body = event.body.as(Roles::PermissionsUpdate::Events::Accepted::Body)
          @state.permissions = body.permissions
          @state.pending_permissions = nil
          @state.has_pending_permissions_update = false
        end
      end
    end
  end
end
