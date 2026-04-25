module CrystalBank::Domains::Scopes
  module Aggregates
    module Concerns
      module NameChange
        def apply(event : Scopes::NameChange::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)
          body = event.body.as(Scopes::NameChange::Events::Accepted::Body)
          @state.name = body.name
        end
      end
    end
  end
end
