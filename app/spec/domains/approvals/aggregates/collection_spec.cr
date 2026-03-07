require "../../../spec_helper"

describe CrystalBank::Domains::Approvals::Aggregates::Concerns::Collection do
  describe "#apply" do
    it "Properly populates the aggregate when an approval is collected" do
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")
      user_id = UUID.new("00000000-0000-0000-0000-300000000001")

      aggregate = Approvals::Aggregate.new(aggregate_id)

      # Creation request
      creation_event = Approvals::Creation::Events::Requested.new(
        actor_id: UUID.new("00000000-0000-0000-0000-000000000000"),
        aggregate_id: aggregate_id,
        command_handler: "test",
        scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
        source_aggregate_type: "Account",
        source_aggregate_id: UUID.new("00000000-0000-0000-0000-200000000001"),
        required_approvals: [
          "write_accounts_opening_compliance_approval",
          "write_accounts_opening_board_approval",
        ]
      )
      aggregate.apply(creation_event)

      # Collected
      collected_event = Approvals::Collection::Events::Collected.new(
        actor_id: user_id,
        aggregate_id: aggregate_id,
        aggregate_version: aggregate.state.aggregate_version + 1,
        command_handler: "test",
        user_id: user_id,
        permissions: ["write_accounts_opening_compliance_approval"]
      )
      aggregate.apply(collected_event)

      state = aggregate.state
      state.aggregate_version.should eq(2)
      state.collected_approvals.size.should eq(1)
      state.collected_approvals.first.user_id.should eq(user_id)
      state.collected_approvals.first.permissions.should eq(["write_accounts_opening_compliance_approval"])
      state.completed.should eq(false)
    end

    it "Sets completed to true when completed event is applied" do
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")

      aggregate = Approvals::Aggregate.new(aggregate_id)

      # Creation request
      creation_event = Approvals::Creation::Events::Requested.new(
        actor_id: UUID.new("00000000-0000-0000-0000-000000000000"),
        aggregate_id: aggregate_id,
        command_handler: "test",
        scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
        source_aggregate_type: "Account",
        source_aggregate_id: UUID.new("00000000-0000-0000-0000-200000000001"),
        required_approvals: ["write_accounts_opening_compliance_approval"]
      )
      aggregate.apply(creation_event)

      # Collected
      collected_event = Approvals::Collection::Events::Collected.new(
        actor_id: UUID.new("00000000-0000-0000-0000-300000000001"),
        aggregate_id: aggregate_id,
        aggregate_version: 2,
        command_handler: "test",
        user_id: UUID.new("00000000-0000-0000-0000-300000000001"),
        permissions: ["write_accounts_opening_compliance_approval"]
      )
      aggregate.apply(collected_event)

      # Completed
      completed_event = Approvals::Collection::Events::Completed.new(
        actor_id: UUID.new("00000000-0000-0000-0000-300000000001"),
        aggregate_id: aggregate_id,
        aggregate_version: 3,
        command_handler: "test"
      )
      aggregate.apply(completed_event)

      state = aggregate.state
      state.aggregate_version.should eq(3)
      state.completed.should eq(true)
    end
  end
end
