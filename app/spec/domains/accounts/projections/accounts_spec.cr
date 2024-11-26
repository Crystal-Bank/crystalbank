require "../../../spec_helper"
require "../events/opening/accepted_spec"
require "../events/opening/requested_spec"

describe CrystalBank::Domains::Customers::Projections::Customers do
  it "correctly applies 'Accounts::Opening::Events::Accepted' event" do
    projection = Accounts::Projections::Accounts.new
    uuid =  UUID.v7

    event_1 = Test::Account::Events::Opening::Requested.new.create(aggr_id: uuid)
    event_2 = Test::Account::Events::Opening::Accepted.new.create(aggr_id: uuid)
    TEST_EVENT_STORE.append(event_1)
    TEST_EVENT_STORE.append(event_2)

    projection.apply(event_2)

    count = TEST_PROJECTION_DB.scalar(%(SELECT count(*) FROM "projections"."accounts" WHERE uuid = $1), uuid)
    count.should eq(1)
  end
end
