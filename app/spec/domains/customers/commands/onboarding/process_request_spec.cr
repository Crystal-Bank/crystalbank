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

  it "creates an approval with a subject snapshot containing name and type" do
    customer_id = UUID.v7

    event = Test::Customer::Events::Onboarding::Requested.new.create(aggr_id: customer_id)
    TEST_EVENT_STORE.append(event)

    approval_id = Customers::Onboarding::Commands::ProcessRequest.new(aggregate_id: customer_id).call
    apply_projection(approval_id)

    approval = Approvals::Queries::Approvals.new.find_by_source("Customer", customer_id)
    approval.should_not be_nil

    subject = approval.not_nil!.subject
    subject.should_not be_nil
    subject.not_nil!.title.should eq("Customer Onboarding")
    subject.not_nil!.summary.should contain("Peter Pan")
    subject.not_nil!.summary.should contain("individual")
    field_labels = subject.not_nil!.fields.map(&.label)
    field_labels.should contain("Name")
    field_labels.should contain("Type")
    subject.not_nil!.fields.find { |f| f.label == "Name" }.not_nil!.value.should eq("Peter Pan")
    subject.not_nil!.fields.find { |f| f.label == "Type" }.not_nil!.value.should eq("individual")
  end
end
