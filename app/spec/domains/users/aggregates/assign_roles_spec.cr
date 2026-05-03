require "../../../spec_helper"

describe CrystalBank::Domains::Users::Aggregates::Concerns::AssignRoles do
  it "adds role_ids to the user when AssignRoles::Accepted is applied" do
    user_id = UUID.v7
    role_id = UUID.v7

    onboarded = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
    accepted = Test::User::Events::AssignRoles::Accepted.new.create(aggr_id: user_id, role_ids: [role_id])

    TEST_EVENT_STORE.append(onboarded)
    TEST_EVENT_STORE.append(accepted)

    aggregate = Users::Aggregate.new(user_id)
    aggregate.hydrate

    aggregate.state.role_ids.should contain(role_id)
  end

  it "deduplicates role_ids when the same role is accepted twice" do
    user_id = UUID.v7
    role_id = UUID.v7

    onboarded = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
    first = Test::User::Events::AssignRoles::Accepted.new.create(aggr_id: user_id, role_ids: [role_id])
    second = Users::AssignRoles::Events::Accepted.new(
      actor_id: nil,
      aggregate_id: user_id,
      aggregate_version: 4,
      command_handler: "test",
      role_ids: [role_id],
    )

    TEST_EVENT_STORE.append(onboarded)
    TEST_EVENT_STORE.append(first)
    TEST_EVENT_STORE.append(second)

    aggregate = Users::Aggregate.new(user_id)
    aggregate.hydrate

    aggregate.state.role_ids.count(role_id).should eq(1)
  end
end
