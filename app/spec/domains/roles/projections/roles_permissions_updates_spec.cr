require "../../../spec_helper"

describe CrystalBank::Domains::Roles::Projections::RolesPermissionsUpdates do
  it "inserts a pending_approval row when 'Roles::PermissionsUpdate::Events::Requested' is applied" do
    role_id = UUID.v7
    update_request_id = UUID.v7

    # Seed role into projection so the scope_id lookup succeeds
    req = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
    acc = Test::Role::Events::Creation::Accepted.new.create(aggr_id: role_id)
    TEST_EVENT_STORE.append(req)
    TEST_EVENT_STORE.append(acc)
    Roles::Projections::Roles.new.apply(req)
    Roles::Projections::Roles.new.apply(acc)

    event = Test::Role::Events::PermissionsUpdate::Requested.new.create(
      aggr_id: update_request_id,
      role_id: role_id
    )
    TEST_EVENT_STORE.append(event)
    Roles::Projections::RolesPermissionsUpdates.new.apply(event)

    row = TEST_PROJECTION_DB.query_one(
      %(SELECT status FROM "projections"."roles_permissions_updates" WHERE uuid = $1),
      update_request_id,
      as: String
    )
    row.should eq("pending_approval")
  end

  it "records the submitted permissions in the projection row" do
    role_id = UUID.v7
    update_request_id = UUID.v7

    req = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
    acc = Test::Role::Events::Creation::Accepted.new.create(aggr_id: role_id)
    TEST_EVENT_STORE.append(req)
    TEST_EVENT_STORE.append(acc)
    Roles::Projections::Roles.new.apply(req)
    Roles::Projections::Roles.new.apply(acc)

    event = Test::Role::Events::PermissionsUpdate::Requested.new.create(
      aggr_id: update_request_id,
      role_id: role_id
    )
    TEST_EVENT_STORE.append(event)
    Roles::Projections::RolesPermissionsUpdates.new.apply(event)

    permissions_json = TEST_PROJECTION_DB.query_one(
      %(SELECT permissions FROM "projections"."roles_permissions_updates" WHERE uuid = $1),
      update_request_id,
      as: String
    )
    permissions_json.should contain("write_roles_permissions_update_request")
  end

  it "transitions status to 'completed' when 'Roles::PermissionsUpdate::Events::Completed' is applied" do
    role_id = UUID.v7
    update_request_id = UUID.v7

    req = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
    acc = Test::Role::Events::Creation::Accepted.new.create(aggr_id: role_id)
    TEST_EVENT_STORE.append(req)
    TEST_EVENT_STORE.append(acc)
    Roles::Projections::Roles.new.apply(req)
    Roles::Projections::Roles.new.apply(acc)

    requested_event = Test::Role::Events::PermissionsUpdate::Requested.new.create(
      aggr_id: update_request_id,
      role_id: role_id
    )
    TEST_EVENT_STORE.append(requested_event)
    Roles::Projections::RolesPermissionsUpdates.new.apply(requested_event)

    completed_event = Test::Role::Events::PermissionsUpdate::Completed.new.create(
      aggr_id: update_request_id,
      aggregate_version: 2
    )
    TEST_EVENT_STORE.append(completed_event)
    Roles::Projections::RolesPermissionsUpdates.new.apply(completed_event)

    row = TEST_PROJECTION_DB.query_one(
      %(SELECT status FROM "projections"."roles_permissions_updates" WHERE uuid = $1),
      update_request_id,
      as: String
    )
    row.should eq("completed")
  end
end
