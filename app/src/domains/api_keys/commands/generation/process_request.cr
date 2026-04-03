module CrystalBank::Domains::ApiKeys
  module Generation
    module Commands
      class ProcessRequest < ES::Command
        def call
          aggregate_id = @aggregate_id.as(UUID)

          # Build the api key aggregate
          aggregate = ApiKeys::Aggregate.new(aggregate_id)
          aggregate.hydrate

          scope_id = aggregate.state.scope_id.as(UUID)

          # Create an approval workflow for this api key generation
          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "ApiKey",
            source_aggregate_id: aggregate_id,
            scope_id: scope_id,
            required_approvals: [
              "write_api_keys_generation_approval",
            ],
            actor_id: aggregate.state.requestor_id
          )
        end
      end
    end
  end
end
