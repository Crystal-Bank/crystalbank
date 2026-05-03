require "../../../../spec_helper"

describe CrystalBank::Domains::Users::AssignRoles::Commands::ProcessApproval do
  it "assigns roles to the user after the approval is completed" do
    scope_id = UUID.new("00000000-0000-0000-0000-100000000001")
    user_id = UUID.v7
    role_id = UUID.v7

    onboarded = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
    TEST_EVENT_STORE.append(onboarded)

    requested = Test::User::Events::AssignRoles::Requested.new.create(user_id: user_id, role_ids: [role_id])
    request_id = UUID.new(requested.header.aggregate_id.to_s)
    TEST_EVENT_STORE.append(requested)

    approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "UserRolesAssignment",
      source_aggregate_id: request_id,
      scope_id: scope_id,
      required_approvals: ["write_users_assign_roles_approval"],
      actor_id: UUID.v7,
    )

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    apply_projection(approval_id)

    aggregate = Users::Aggregate.new(user_id)
    aggregate.hydrate

    aggregate.state.role_ids.should contain(role_id)
  end

  it "ignores a completed approval with a different source aggregate type" do
    approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "SomeUnhandledType",
      source_aggregate_id: UUID.v7,
      scope_id: UUID.v7,
      required_approvals: ["write_users_assign_roles_approval"],
      actor_id: UUID.v7,
    )

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    apply_projection(approval_id)
  end

  it "does not process the same approval twice" do
    scope_id = UUID.new("00000000-0000-0000-0000-100000000001")
    user_id = UUID.v7
    role_id = UUID.v7

    onboarded = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
    TEST_EVENT_STORE.append(onboarded)

    requested = Test::User::Events::AssignRoles::Requested.new.create(user_id: user_id, role_ids: [role_id])
    request_id = UUID.new(requested.header.aggregate_id.to_s)
    TEST_EVENT_STORE.append(requested)

    approval_id = Approvals::Creation::Commands::Request.new.call(
      source_aggregate_type: "UserRolesAssignment",
      source_aggregate_id: request_id,
      scope_id: scope_id,
      required_approvals: ["write_users_assign_roles_approval"],
      actor_id: UUID.v7,
    )

    completed_event = Approvals::Collection::Events::Completed.new(
      actor_id: nil,
      aggregate_id: approval_id,
      aggregate_version: 2,
      command_handler: "test",
      comment: "approved",
    )
    TEST_EVENT_STORE.append(completed_event)

    apply_projection(approval_id)
    apply_projection(approval_id)

    aggregate = Users::Aggregate.new(user_id)
    aggregate.hydrate

    aggregate.state.role_ids.count(role_id).should eq(1)
  end
end
