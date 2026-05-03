module CrystalBank::Domains::Users
  module AssignRoles
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "UserRolesAssignment", "user.assign_roles.requested" do
          attribute :user_id, UUID
          attribute :role_ids, Array(UUID)
          attribute :scope_id, UUID
        end
      end
    end
  end
end
