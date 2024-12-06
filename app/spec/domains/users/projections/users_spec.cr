require "../../../spec_helper"

describe CrystalBank::Domains::Users::Projections::Users do
  it "correctly applies 'Users::Onboarding::Events::Accepted' event" do
    projection = Users::Projections::Users.new
    uuid = UUID.v7

    event_1 = Test::User::Events::Onboarding::Requested.new.create(aggr_id: uuid)
    event_2 = Test::User::Events::Onboarding::Accepted.new.create(aggr_id: uuid)
    TEST_EVENT_STORE.append(event_1)
    TEST_EVENT_STORE.append(event_2)

    projection.apply(event_2)

    count = TEST_PROJECTION_DB.scalar(%(SELECT count(*) FROM "projections"."users" WHERE uuid = $1), uuid)
    count.should eq(1)
  end
end
