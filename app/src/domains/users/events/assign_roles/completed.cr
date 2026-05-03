module CrystalBank::Domains::Users
  module AssignRoles
    module Events
      class Completed < ES::Event
        include ::ES::EventDSL

        define_event "UserRolesAssignment", "user.assign_roles.completed"
      end
    end
  end
end
