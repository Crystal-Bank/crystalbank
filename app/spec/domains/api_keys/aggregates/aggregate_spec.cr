require "../../../spec_helper"

describe CrystalBank::Domains::ApiKeys::Aggregate do
  it "can be initialized" do
    uuid = UUID.v7
    aggr = CrystalBank::Domains::ApiKeys::Aggregate.new(uuid)

    aggr.state.aggregate_id.should eq(uuid)
    aggr.state.aggregate_type.should eq("ApiKey")
    aggr.state.aggregate_version.should eq(0)

    aggr.state.active.should eq(false)
    aggr.state.name.should eq(nil)
    aggr.state.user_id.should eq(nil)
    aggr.state.encrypted_secret.should eq(nil)
    aggr.state.revoked_at.should eq(nil)
  end
end
