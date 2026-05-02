module CrystalBank::Domains::Users
  module Aggregates
    module Concerns
      module AssignRoles
        def apply(event : Users::AssignRoles::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Users::AssignRoles::Events::Accepted::Body)
          @state.role_ids = (@state.role_ids + body.role_ids).uniq
        end
      end
    end
  end
end
