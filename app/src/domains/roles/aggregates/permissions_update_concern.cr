module CrystalBank::Domains::Roles
  module Aggregates
    module Concerns
      module PermissionsUpdate
        # Apply 'Roles::PermissionsUpdate::Events::Accepted' to the aggregate state
        def apply(event : Roles::PermissionsUpdate::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)
          body = event.body.as(Roles::PermissionsUpdate::Events::Accepted::Body)
          @state.permissions = body.permissions
        end
      end
    end
  end
end
