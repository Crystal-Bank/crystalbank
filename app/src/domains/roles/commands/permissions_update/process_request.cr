module CrystalBank::Domains::Roles
  module PermissionsUpdate
    module Commands
      class ProcessRequest < ES::Command
        def call
          role_id = @aggregate_id.as(UUID)

          role = Roles::Aggregate.new(role_id)
          role.hydrate

          scope_id = role.state.scope_id.as(UUID)

          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "RolePermissionsUpdate",
            source_aggregate_id: role_id,
            scope_id: scope_id,
            required_approvals: [
              "write_roles_permissions_update_approval",
            ],
            actor_id: role.state.requestor_id
          )
        end
      end
    end
  end
end
