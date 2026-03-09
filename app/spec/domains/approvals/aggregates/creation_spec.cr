require "../../../spec_helper"

describe CrystalBank::Domains::Approvals::Aggregates::Concerns::Creation do
  describe "#apply" do
    it "Properly populates the aggregate on approval creation" do
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")
      scope_id = UUID.new("00000000-0000-0000-0000-100000000001")
      source_aggregate_type = "Account"
      source_aggregate_id = UUID.new("00000000-0000-0000-0000-200000000001")
      required_approvals = [
        "write_accounts_opening_compliance_approval",
        "write_accounts_opening_board_approval",
      ]

      aggregate = Approvals::Aggregate.new(aggregate_id)

      # Creation request
      event = Approvals::Creation::Events::Requested.new(
        actor_id: UUID.new("00000000-0000-0000-0000-000000000000"),
        aggregate_id: aggregate_id,
        command_handler: "test",
        scope_id: scope_id,
        source_aggregate_type: source_aggregate_type,
        source_aggregate_id: source_aggregate_id,
        required_approvals: required_approvals
      )
      aggregate.apply(event)

      state = aggregate.state
      state.aggregate_id.should eq(aggregate_id)
      state.aggregate_version.should eq(1)
      state.scope_id.should eq(scope_id)
      state.source_aggregate_type.should eq(source_aggregate_type)
      state.source_aggregate_id.should eq(source_aggregate_id)
      state.required_approvals.should eq(required_approvals)
      state.completed.should eq(false)
    end
  end
end
