require "../../../spec_helper"

describe CrystalBank::Domains::Roles::Aggregate do
  it "can be initialized" do
    uuid = UUID.v7
    aggr = CrystalBank::Domains::Roles::Aggregate.new(uuid)

    aggr.state.aggregate_id.should eq(uuid)
    aggr.state.aggregate_type.should eq("Role")
    aggr.state.aggregate_version.should eq(0)

    aggr.state.name.should eq(nil)
    aggr.state.permissions.should eq(nil)
    aggr.state.scopes.should eq(nil)
  end
end
