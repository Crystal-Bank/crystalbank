module CrystalBank::Domains::Users
  module RemoveRoles
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "User", "user.remove_roles.requested" do
          attribute :role_ids, Array(UUID)
          attribute :scope_id, UUID
        end
      end
    end
  end
end
