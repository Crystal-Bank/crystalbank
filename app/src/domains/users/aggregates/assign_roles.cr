module CrystalBank::Domains::Users
  module Aggregates
    module Concerns
      module AssignRoles
        # Apply 'Users::AssignRoles::Events::Accepted' to the aggregate state
        def apply(event : Users::AssignRoles::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)

          _body = event.body.as(Users::AssignRoles::Events::Accepted::Body)
        end

        # Apply 'Users::AssignRoles::Events::Requested' to the aggregate state
        def apply(event : Users::AssignRoles::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          _body = event.body.as(Users::AssignRoles::Events::Requested::Body)
        end
      end
    end
  end
end
