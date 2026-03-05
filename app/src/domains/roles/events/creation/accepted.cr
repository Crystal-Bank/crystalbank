module CrystalBank::Domains::Roles
  module Creation
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "Role", "role.creation.accepted"
      end
    end
  end
end
