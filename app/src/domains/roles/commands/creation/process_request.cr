module CrystalBank::Domains::Roles
  module Creation
    module Commands
      class ProcessRequest < ES::Command
        def call
          aggregate_id = @aggregate_id.as(UUID)

          # Build the role aggregate
          aggregate = Roles::Aggregate.new(aggregate_id)
          aggregate.hydrate

          scope_id = aggregate.state.scope_id.as(UUID)

          # Create an approval workflow for this role creation
          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "Role",
            source_aggregate_id: aggregate_id,
            scope_id: scope_id,
            required_approvals: [
              "write_roles_creation_approval",
            ],
            actor_id: aggregate.state.requestor_id
          )
        end
      end
    end
  end
end
