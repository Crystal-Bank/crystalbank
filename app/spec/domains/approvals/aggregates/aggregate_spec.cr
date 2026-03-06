require "../../../spec_helper"

describe CrystalBank::Domains::Approvals::Aggregate do
  it "can be initialized" do
    aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")
    aggregate = Approvals::Aggregate.new(aggregate_id)

    aggregate.state.aggregate_id.should eq(aggregate_id)
    aggregate.state.aggregate_version.should eq(0)
    aggregate.state.completed.should eq(false)
    aggregate.state.required_approvals.should be_empty
    aggregate.state.collected_approvals.should be_empty
  end
end
