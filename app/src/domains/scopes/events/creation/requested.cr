module CrystalBank::Domains::Scopes
  module Creation
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "Scope", "scope.creation.requested" do
          attribute :name, String
          attribute :parent_scope_id, UUID?
          attribute :scope_id, UUID
        end
      end
    end
  end
end
