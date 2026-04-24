module CrystalBank::Domains::Users
  module RemoveRoles
    module Commands
      class ProcessRequest < ES::Command
        def call
          request_aggregate_id = @aggregate_id.as(UUID)

          # Hydrate the request aggregate to get intent
          request = Users::RemoveRolesRequest::Aggregate.new(request_aggregate_id)
          request.hydrate

          user_id = request.state.user_id.as(UUID)

          # Hydrate the user aggregate to get scope_id
          user = Users::Aggregate.new(user_id)
          user.hydrate

          scope_id = user.state.scope_id.as(UUID)

          # Create an approval workflow for this role removal
          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "UserRolesRemoval",
            source_aggregate_id: request_aggregate_id,
            scope_id: scope_id,
            required_approvals: [
              "write_users_remove_roles_approval",
            ],
            actor_id: request.state.requestor_id
          )
        end
      end
    end
  end
end
