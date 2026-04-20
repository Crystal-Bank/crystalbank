require "../../../spec_helper"
require "../events/creation/accepted_spec"
require "../events/creation/requested_spec"
require "../events/permissions_update/requested_spec"
require "../events/permissions_update/completed_spec"
require "../events/permissions_update/accepted_spec"

describe CrystalBank::Domains::Roles::Projections::Roles do
  it "inserts a pending row when 'Roles::Creation::Events::Requested' is applied" do
    projection = Roles::Projections::Roles.new
    uuid = UUID.v7

    event = Test::Role::Events::Creation::Requested.new.create(aggr_id: uuid)
    TEST_EVENT_STORE.append(event)

    projection.apply(event)

    row = TEST_PROJECTION_DB.query_one(%(SELECT status FROM "projections"."roles" WHERE uuid = $1), uuid, as: String)
    row.should eq("pending_approval")
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

    row = TEST_PROJECTION_DB.query_one(%(SELECT status FROM "projections"."roles" WHERE uuid = $1), uuid, as: String)
    row.should eq("active")
  end

  it "updates permissions when 'Roles::PermissionsUpdate::Events::Accepted' is applied" do
    projection = Roles::Projections::Roles.new
    uuid = UUID.v7

    event_1 = Test::Role::Events::Creation::Requested.new.create(aggr_id: uuid)
    event_2 = Test::Role::Events::Creation::Accepted.new.create(aggr_id: uuid)
    TEST_EVENT_STORE.append(event_1)
    TEST_EVENT_STORE.append(event_2)
    projection.apply(event_1)
    projection.apply(event_2)

    event_3 = Test::Role::Events::PermissionsUpdate::Accepted.new.create(aggr_id: uuid, aggregate_version: 3)
    TEST_EVENT_STORE.append(event_3)
    projection.apply(event_3)

    permissions_json = TEST_PROJECTION_DB.query_one(
      %(SELECT permissions FROM "projections"."roles" WHERE uuid = $1),
      uuid,
      as: String
    )
    permissions_json.should contain("write_roles_permissions_update_request")
  end
end
