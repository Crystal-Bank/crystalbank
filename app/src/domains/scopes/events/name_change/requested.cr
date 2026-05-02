module CrystalBank::Domains::Scopes
  module NameChange
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "ScopeNameChange", "scope.name_change.requested" do
          attribute :scope_id, UUID
          attribute :name, String
        end
      end
    end
  end
end
