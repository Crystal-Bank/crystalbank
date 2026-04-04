require "../../../../spec_helper"

describe CrystalBank::Domains::Roles::Creation::Commands::ProcessRequest do
  # FIXME: Eventual consistent projection
  # it "creates an approval workflow when a role creation is requested" do
  #   role_id = UUID.v7
  #
  #   event = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
  #   TEST_EVENT_STORE.append(event)
  #
  #   Roles::Creation::Commands::ProcessRequest.new(aggregate_id: role_id).call
  #
  #   apply_projection(role_id)
  #
  #   approval = Approvals::Queries::Approvals.new.find_by_source("Role", role_id)
  #   approval.should_not be_nil
  #   approval.not_nil!.completed.should be_false
  #   approval.not_nil!.required_approvals.should contain("write_roles_creation_approval")
  # end

  it "does not accept the role before approval" do
    role_id = UUID.v7

    event = Test::Role::Events::Creation::Requested.new.create(aggr_id: role_id)
    TEST_EVENT_STORE.append(event)

    Roles::Creation::Commands::ProcessRequest.new(aggregate_id: role_id).call

    aggregate = Roles::Aggregate.new(role_id)
    aggregate.hydrate

    aggregate.state.aggregate_version.should eq(1)
  end
end
