require "../../../spec_helper"
require "../events/onboarding/accepted_spec"
require "../events/onboarding/requested_spec"

describe CrystalBank::Domains::Customers::Projections::Customers do
  it "correctly applies 'Customers::Onboarding::Events::Accepted' event" do
    projection = ::Customers::Projections::Customers.new
    uuid =  UUID.v7

    event_1 = Test::Customer::Events::Onboarding::Requested.new.create(aggr_id: uuid)
    event_2 = Test::Customer::Events::Onboarding::Accepted.new.create(aggr_id: uuid)
    TEST_EVENT_STORE.append(event_1)
    TEST_EVENT_STORE.append(event_2)

    projection.apply(event_2)

    count = TEST_PROJECTION_DB.scalar(%(SELECT count(*) FROM "projections"."customers" WHERE uuid = $1), uuid)
    count.should eq(1)
  end
end
