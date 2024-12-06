require "../../../spec_helper"

describe CrystalBank::Domains::Users::Aggregate do
  it "can be initialized" do
    uuid = UUID.v7
    aggr = CrystalBank::Domains::Users::Aggregate.new(uuid)

    aggr.state.aggregate_id.should eq(uuid)
    aggr.state.aggregate_type.should eq("User")
    aggr.state.aggregate_version.should eq(0)

    aggr.state.onboarded.should eq(false)
    aggr.state.name.should eq(nil)
    aggr.state.email.should eq(nil)
  end
end
