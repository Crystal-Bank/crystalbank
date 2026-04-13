module CrystalBank::Domains::Roles
  module PermissionsUpdate
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "RolePermissionsUpdate", "role.permissions_update.requested" do
          attribute :role_id, UUID
          attribute :permissions_to_add, Array(CrystalBank::Permissions)
          attribute :permissions_to_remove, Array(CrystalBank::Permissions)
        end
      end
    end
  end
end
