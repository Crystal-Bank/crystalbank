module CrystalBank::Domains::Roles
  module PermissionsUpdate
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "Role", "role.permissions_update.requested" do
          attribute :permissions, Array(CrystalBank::Permissions)
        end
      end
    end
  end
end
