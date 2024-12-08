require "../../../spec_helper"
require "../events/generation/accepted_spec"
require "../events/generation/requested_spec"

describe CrystalBank::Domains::ApiKeys::Projections::ApiKeys do
  it "correctly applies 'ApiKeys::Generation::Events::Accepted' event" do
    projection = ApiKeys::Projections::ApiKeys.new
    uuid = UUID.v7

    event_1 = Test::ApiKey::Events::Generation::Requested.new.create(aggr_id: uuid)
    event_2 = Test::ApiKey::Events::Generation::Accepted.new.create(aggr_id: uuid)
    TEST_EVENT_STORE.append(event_1)
    TEST_EVENT_STORE.append(event_2)

    projection.apply(event_2)

    count = TEST_PROJECTION_DB.scalar(%(SELECT count(*) FROM "projections"."api_keys" WHERE uuid = $1), uuid)
    count.should eq(1)
  end

  it "correctly applies 'ApiKeys::Revocation::Events::Accepted' event" do
    projection = ApiKeys::Projections::ApiKeys.new
    uuid = UUID.v7

    event_1 = Test::ApiKey::Events::Generation::Requested.new.create(aggr_id: uuid)
    event_2 = Test::ApiKey::Events::Generation::Accepted.new.create(aggr_id: uuid)
    event_3 = Test::ApiKey::Events::Revocation::Requested.new.create(aggr_id: uuid, version: 3)
    event_4 = Test::ApiKey::Events::Revocation::Accepted.new.create(aggr_id: uuid, version: 4)
    TEST_EVENT_STORE.append(event_1)
    TEST_EVENT_STORE.append(event_2)
    TEST_EVENT_STORE.append(event_3)
    TEST_EVENT_STORE.append(event_4)

    projection.apply(event_2)
    projection.apply(event_4)

    active, revoked_at = TEST_PROJECTION_DB.query_one(%(SELECT active, revoked_at FROM "projections"."api_keys" WHERE uuid = $1), uuid, as: {Bool, Time})
    active.should eq(false)
    revoked_at.to_unix.should eq(event_1.header.created_at.to_unix)
  end
end
