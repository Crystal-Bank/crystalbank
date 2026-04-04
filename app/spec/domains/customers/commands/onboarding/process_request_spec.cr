require "../../../../spec_helper"

describe CrystalBank::Domains::Customers::Onboarding::Commands::ProcessRequest do
  it "does not mark the customer as onboarded before approval" do
    customer_id = UUID.v7

    event = Test::Customer::Events::Onboarding::Requested.new.create(aggr_id: customer_id)
    TEST_EVENT_STORE.append(event)

    Customers::Onboarding::Commands::ProcessRequest.new(aggregate_id: customer_id).call

    aggregate = Customers::Aggregate.new(customer_id)
    aggregate.hydrate

    aggregate.state.onboarded.should be_false
  end

  it "creates a pending approval workflow for the customer" do
    customer_id = UUID.v7

    event = Test::Customer::Events::Onboarding::Requested.new.create(aggr_id: customer_id)
    TEST_EVENT_STORE.append(event)

    Customers::Onboarding::Commands::ProcessRequest.new(aggregate_id: customer_id).call

    approval = Approvals::Queries::Approvals.new.find_by_source("Customer", customer_id)
    approval.should_not be_nil
    approval.not_nil!.completed.should be_false
    approval.not_nil!.required_approvals.should contain("write_customers_onboarding_compliance_approval")
  end
end
