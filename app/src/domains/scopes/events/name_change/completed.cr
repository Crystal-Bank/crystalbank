module CrystalBank::Domains::Scopes
  module NameChange
    module Events
      class Completed < ES::Event
        include ::ES::EventDSL

        define_event "ScopeNameChange", "scope.name_change.completed"
      end
    end
  end
end
