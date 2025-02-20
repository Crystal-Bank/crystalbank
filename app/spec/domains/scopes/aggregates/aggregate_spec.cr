require "../../../spec_helper"

describe CrystalBank::Domains::Scopes::Aggregate do
  it "can be initialized" do
    uuid = UUID.v7
    aggr = CrystalBank::Domains::Scopes::Aggregate.new(uuid)

    aggr.state.aggregate_id.should eq(uuid)
    aggr.state.aggregate_type.should eq("Scope")
    aggr.state.aggregate_version.should eq(0)

    aggr.state.name.should eq(nil)
    aggr.state.parent_scope_id.should eq(nil)
  end
end
