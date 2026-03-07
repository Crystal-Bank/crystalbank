module CrystalBank::Domains::Accounts
  module Opening
    module Commands
      class ProcessRequest < ES::Command
        def call
          aggregate_id = @aggregate_id.as(UUID)

          # Build the account aggregate
          aggregate = Accounts::Aggregate.new(aggregate_id)
          aggregate.hydrate

          scope_id = aggregate.state.scope_id.as(UUID)

          # Create an approval workflow for this account opening
          Approvals::Creation::Commands::Request.new.call(
            source_aggregate_type: "Account",
            source_aggregate_id: aggregate_id,
            scope_id: scope_id,
            required_approvals: [
              "write_accounts_opening_compliance_approval",
              "write_accounts_opening_board_approval",
            ],
            actor_id: nil,
            requestor_id: aggregate.state.requestor_id
          )
        end
      end
    end
  end
end
