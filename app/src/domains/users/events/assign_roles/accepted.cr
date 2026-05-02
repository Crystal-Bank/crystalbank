module CrystalBank::Domains::Users
  module AssignRoles
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "User", "user.assign_roles.accepted" do
          attribute :role_ids, Array(UUID)
        end
      end
    end
  end
end
