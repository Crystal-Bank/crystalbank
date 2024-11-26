require "../../../spec_helper"

describe CrystalBank::Domains::Customers::Aggregate do
  it "can be initialized" do
    uuid = UUID.v7
    aggr = CrystalBank::Domains::Customers::Aggregate.new(uuid)

    aggr.state.aggregate_id.should eq(uuid)
    aggr.state.aggregate_type.should eq("Customer")
    aggr.state.aggregate_version.should eq(0)
    
    aggr.state.name.should eq(nil)
    aggr.state.onboarded.should eq(false)
    aggr.state.type.should eq(nil)
  end
end
