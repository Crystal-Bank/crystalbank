module CrystalBank::Domains::Roles
  module Aggregates
    module Concerns
      module Creation
        # Apply 'Roles::Creation::Events::Accepted' to the aggregate state
        def apply(event : Roles::Creation::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Roles::Creation::Events::Accepted::Body)
        end

        # Apply 'Roles::Creation::Events::Requested' to the aggregate state
        def apply(event : Roles::Creation::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Roles::Creation::Events::Requested::Body)
          @state.name = body.name
          @state.permissions = body.permissions
          @state.scope_id = body.scope_id
          @state.scopes = body.scopes
        end
      end
    end
  end
end
