module CrystalBank::Domains::Users
  module Aggregates
    module Concerns
      module AssignRoles
        # Apply 'Users::AssignRoles::Events::Accepted' to the aggregate state
        def apply(event : Users::AssignRoles::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)

          @state.role_ids = @state.role_ids.concat(@state.pending_role_id_assignments).uniq
          @state.pending_role_id_assignments = [] of UUID
        end

        # Apply 'Users::AssignRoles::Events::Requested' to the aggregate state
        def apply(event : Users::AssignRoles::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Users::AssignRoles::Events::Requested::Body)
          @state.pending_role_id_assignments = body.role_ids
        end
      end
    end
  end
end
