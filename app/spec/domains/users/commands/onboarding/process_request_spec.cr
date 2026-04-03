require "../../../../spec_helper"

describe CrystalBank::Domains::Users::Onboarding::Commands::ProcessRequest do
  # FIXME: Eventual consistent projection
  # it "creates an approval workflow for the user when onboarding is requested" do
  #   scope_id = UUID.v7
  #   user_id = UUID.v7

  #   event = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
  #   TEST_EVENT_STORE.append(event)

  #   Users::Onboarding::Commands::ProcessRequest.new(aggregate_id: user_id).call

  #   apply_projection(user_id)

  #   approval = Approvals::Queries::Approvals.new.find_by_source("User", user_id)
  #   approval.should_not be_nil
  #   approval.not_nil!.completed.should be_false
  #   approval.not_nil!.required_approvals.should contain("write_users_onboarding_compliance_approval")
  # end

  it "does not mark the user as onboarded before approval" do
    user_id = UUID.v7

    event = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_id)
    TEST_EVENT_STORE.append(event)

    Users::Onboarding::Commands::ProcessRequest.new(aggregate_id: user_id).call

    aggregate = Users::Aggregate.new(user_id)
    aggregate.hydrate

    aggregate.state.onboarded.should be_false
  end
end
