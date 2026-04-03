module CrystalBank::Domains::Users
  module Onboarding
    module Commands
      class ProcessRequest < ES::Command
        def call
          aggregate_id = @aggregate_id.as(UUID)

          # Build the user aggregate
          aggregate = Users::Aggregate.new(aggregate_id)
          aggregate.hydrate

          scope_id = aggregate.state.scope_id.as(UUID)

          # Create an approval workflow for this user onboarding
          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "User",
            source_aggregate_id: aggregate_id,
            scope_id: scope_id,
            required_approvals: [
              "write_users_onboarding_compliance_approval",
            ],
            actor_id: aggregate.state.requestor_id
          )
        end
      end
    end
  end
end
