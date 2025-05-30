module CrystalBank::Domains::Scopes
  module Aggregates
    module Concerns
      module Creation
        # Apply 'Scopes::Creation::Events::Accepted' to the aggregate state
        def apply(event : Scopes::Creation::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Scopes::Creation::Events::Accepted::Body)
        end

        # Apply 'Scopes::Creation::Events::Requested' to the aggregate state
        def apply(event : Scopes::Creation::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Scopes::Creation::Events::Requested::Body)
          @state.name = body.name
          @state.parent_scope_id = body.parent_scope_id
          @state.scope_id = body.scope_id
        end
      end
    end
  end
end
