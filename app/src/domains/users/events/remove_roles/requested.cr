module CrystalBank::Domains::Users
  module RemoveRoles
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "UserRolesRemoval", "user.remove_roles.requested" do
          attribute :user_id, UUID
          attribute :role_ids, Array(UUID)
          attribute :scope_id, UUID
        end
      end
    end
  end
end
