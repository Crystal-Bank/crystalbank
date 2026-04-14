module CrystalBank::Domains::Roles
  module PermissionsUpdate
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "RolePermissionsUpdate", "role.permissions_update.requested" do
          attribute :role_id, UUID
          attribute :permissions, Array(CrystalBank::Permissions)
        end
      end
    end
  end
end
