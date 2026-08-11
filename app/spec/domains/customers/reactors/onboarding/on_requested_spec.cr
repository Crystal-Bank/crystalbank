require "../../../../spec_helper"

describe CrystalBank::Domains::Customers::Reactors::Onboarding::OnRequested do
  it "does not mark the customer as onboarded before approval" do
    customer_id = UUID.v7

    event = Test::Customer::Events::Onboarding::Requested.new.create(aggr_id: customer_id)
    TEST_EVENT_STORE.append(event)

    Customers::Reactors::Onboarding::OnRequested.new.call(event)

    aggregate = Customers::Aggregate.new(customer_id)
    aggregate.hydrate

    aggregate.state.onboarded.should be_false
  end

  it "creates an approval with a subject snapshot containing name and type" do
    customer_id = UUID.v7

    event = Test::Customer::Events::Onboarding::Requested.new.create(aggr_id: customer_id)
    TEST_EVENT_STORE.append(event)

    Customers::Reactors::Onboarding::OnRequested.new.call(event)

    # The reactor generates its own approval aggregate ID internally, so recover it
    # by scanning the event store for the Requested event it appended.
    found = nil
    TEST_EVENT_STORE.each_event do |raw|
      next unless raw.header["event_handle"]?.try(&.as_s) == "approval.creation.requested"
      next unless raw.body["source_aggregate_id"]?.try(&.as_s) == customer_id.to_s
      found = UUID.new(raw.header["aggregate_id"].as_s)
    end
    found.should_not be_nil
    apply_projection(found.not_nil!)

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
