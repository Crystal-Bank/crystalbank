module CrystalBank::Domains::Scopes
  module Creation
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "Scope", "scope.creation.accepted"
      end
    end
  end
end
