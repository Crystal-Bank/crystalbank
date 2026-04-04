require "../../../spec_helper"
require "../events/creation/accepted_spec"
require "../events/creation/requested_spec"

describe CrystalBank::Domains::Roles::Projections::Roles do
  it "inserts a pending row when 'Roles::Creation::Events::Requested' is applied" do
    projection = Roles::Projections::Roles.new
    uuid = UUID.v7

    event = Test::Role::Events::Creation::Requested.new.create(aggr_id: uuid)
    TEST_EVENT_STORE.append(event)

    projection.apply(event)

    row = TEST_PROJECTION_DB.query_one(%(SELECT accepted FROM "projections"."roles" WHERE uuid = $1), uuid, as: Bool)
    row.should be_false
  end

  it "correctly applies 'Roles::Creation::Events::Accepted' event" do
    projection = Roles::Projections::Roles.new
    uuid = UUID.v7

    event_1 = Test::Role::Events::Creation::Requested.new.create(aggr_id: uuid)
    event_2 = Test::Role::Events::Creation::Accepted.new.create(aggr_id: uuid)
    TEST_EVENT_STORE.append(event_1)
    TEST_EVENT_STORE.append(event_2)

    projection.apply(event_1)
    projection.apply(event_2)

    row = TEST_PROJECTION_DB.query_one(%(SELECT accepted FROM "projections"."roles" WHERE uuid = $1), uuid, as: Bool)
    row.should be_true
  end
end
