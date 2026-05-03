module CrystalBank::Domains::Users
  module AssignRoles
    module Events
      class Rejected < ES::Event
        include ::ES::EventDSL

        define_event "UserRolesAssignment", "user.assign_roles.rejected"
      end
    end
  end
end
