module CrystalBank::Domains::Roles
  module PermissionsUpdate
    module Events
      class Completed < ES::Event
        include ::ES::EventDSL

        define_event "RolePermissionsUpdate", "role.permissions_update.completed"
      end
    end
  end
end
