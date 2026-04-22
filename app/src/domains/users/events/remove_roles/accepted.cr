module CrystalBank::Domains::Users
  module RemoveRoles
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "User", "user.remove_roles.accepted"
      end
    end
  end
end
