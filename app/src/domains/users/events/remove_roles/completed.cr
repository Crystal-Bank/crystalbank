module CrystalBank::Domains::Users
  module RemoveRoles
    module Events
      class Completed < ES::Event
        include ::ES::EventDSL

        define_event "UserRolesRemoval", "user.remove_roles.completed"
      end
    end
  end
end
