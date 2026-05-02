module CrystalBank::Domains::Users
  module Aggregates
    module Concerns
      module RemoveRoles
        # Apply 'Users::RemoveRoles::Events::Accepted' to the aggregate state
        def apply(event : Users::RemoveRoles::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Users::RemoveRoles::Events::Accepted::Body)
          @state.role_ids = @state.role_ids - body.role_ids
        end
      end
    end
  end
end
