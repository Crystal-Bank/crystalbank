module CrystalBank::Domains::Scopes
  module NameChange
    module Events
      class Accepted < ES::Event
        include ::ES::EventDSL

        define_event "Scope", "scope.name_change.accepted" do
          attribute :name, String
        end
      end
    end
  end
end
