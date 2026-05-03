require "../../../spec_helper"

describe CrystalBank::Domains::Users::Projections::AssignRolesRequests do
  it "inserts a row when a Requested event is applied" do
    user_id = UUID.v7
    role_id = UUID.v7

    event = Test::User::Events::AssignRoles::Requested.new.create(user_id: user_id, role_ids: [role_id])
    request_id = UUID.new(event.header.aggregate_id.to_s)

    projection = Users::Projections::AssignRolesRequests.new
    projection.apply(event)

    count = TEST_PROJECTION_DB.scalar(
      %(SELECT count(*) FROM "projections"."user_assign_roles_requests" WHERE id = $1 AND user_id = $2 AND NOT completed),
      request_id, user_id
    )
    count.should eq(1)
  end

  it "marks the row as completed when a Completed event is applied" do
    user_id = UUID.v7

    requested = Test::User::Events::AssignRoles::Requested.new.create(user_id: user_id)
    request_id = UUID.new(requested.header.aggregate_id.to_s)
    completed = Test::User::Events::AssignRoles::Completed.new.create(aggr_id: request_id)

    projection = Users::Projections::AssignRolesRequests.new
    projection.apply(requested)
    projection.apply(completed)

    count = TEST_PROJECTION_DB.scalar(
      %(SELECT count(*) FROM "projections"."user_assign_roles_requests" WHERE id = $1 AND completed = true),
      request_id
    )
    count.should eq(1)
  end

  it "is idempotent — applying the same Requested event twice inserts only one row" do
    user_id = UUID.v7
    event = Test::User::Events::AssignRoles::Requested.new.create(user_id: user_id)
    request_id = UUID.new(event.header.aggregate_id.to_s)

    projection = Users::Projections::AssignRolesRequests.new
    projection.apply(event)
    projection.apply(event)

    count = TEST_PROJECTION_DB.scalar(
      %(SELECT count(*) FROM "projections"."user_assign_roles_requests" WHERE id = $1),
      request_id
    )
    count.should eq(1)
  end
end
