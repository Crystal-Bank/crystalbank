module CrystalBank::Domains::Roles
  module PermissionsUpdate
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "Role", "role.permissions_update.accepted" do
          attribute :permissions, Array(CrystalBank::Permissions)
        end
      end
    end
  end
end
