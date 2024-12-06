require "../../../spec_helper"

describe CrystalBank::Domains::Accounts::Aggregate do
  it "can be initialized" do
    uuid = UUID.v7
    aggr = CrystalBank::Domains::Accounts::Aggregate.new(uuid)

    aggr.state.aggregate_id.should eq(uuid)
    aggr.state.aggregate_type.should eq("Account")
    aggr.state.aggregate_version.should eq(0)

    aggr.state.customer_ids.should eq(Array(UUID).new)
    aggr.state.open.should eq(false)
    aggr.state.supported_currencies.should eq(Array(CrystalBank::Types::Currencies::Supported).new)
    aggr.state.type.should eq(nil)
  end
end
