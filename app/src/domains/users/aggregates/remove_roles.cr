module CrystalBank::Domains::Users
  module Aggregates
    module Concerns
      module RemoveRoles
        # Apply 'Users::RemoveRoles::Events::Accepted' to the aggregate state
        def apply(event : Users::RemoveRoles::Events::Accepted)
          @state.increase_version(event.header.aggregate_version)

          @state.role_ids = @state.role_ids - @state.pending_role_id_removals
          @state.pending_role_id_removals = [] of UUID
        end

        # Apply 'Users::RemoveRoles::Events::Requested' to the aggregate state
        def apply(event : Users::RemoveRoles::Events::Requested)
          @state.increase_version(event.header.aggregate_version)

          body = event.body.as(Users::RemoveRoles::Events::Requested::Body)
          @state.pending_role_id_removals = body.role_ids
        end
      end
    end
  end
end
