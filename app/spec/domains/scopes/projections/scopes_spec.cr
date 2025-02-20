require "../../../spec_helper"
require "../events/creation/accepted_spec"
require "../events/creation/requested_spec"

describe CrystalBank::Domains::Scopes::Projections::Scopes do
  it "correctly applies 'Scopes::Creation::Events::Accepted' event" do
    projection = Scopes::Projections::Scopes.new
    uuid = UUID.v7

    event_1 = Test::Scope::Events::Creation::Requested.new.create(aggr_id: uuid)
    event_2 = Test::Scope::Events::Creation::Accepted.new.create(aggr_id: uuid)
    TEST_EVENT_STORE.append(event_1)
    TEST_EVENT_STORE.append(event_2)

    projection.apply(event_2)

    count = TEST_PROJECTION_DB.scalar(%(SELECT count(*) FROM "projections"."scopes" WHERE uuid = $1), uuid)
    count.should eq(1)
  end
end
