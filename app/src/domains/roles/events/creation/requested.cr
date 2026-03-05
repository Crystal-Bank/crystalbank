module CrystalBank::Domains::Roles
  module Creation
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "Role", "role.creation.requested" do
          attribute :name, String
          attribute :permissions, Array(CrystalBank::Permissions)
          attribute :scope_id, UUID
          attribute :scopes, Array(UUID)
        end
      end
    end
  end
end
