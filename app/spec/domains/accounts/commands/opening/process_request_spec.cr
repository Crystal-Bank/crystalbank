require "../../../../spec_helper"

describe CrystalBank::Domains::Accounts::Opening::Commands::ProcessRequest do
  it "creates an approval with a subject snapshot containing name, type, and currencies" do
    account_id = UUID.v7

    event = Test::Account::Events::Opening::Requested.new.create(aggr_id: account_id)
    TEST_EVENT_STORE.append(event)

    approval_id = Accounts::Opening::Commands::ProcessRequest.new(aggregate_id: account_id).call
    apply_projection(approval_id)

    approval = Approvals::Queries::Approvals.new.find_by_source("Account", account_id)
    approval.should_not be_nil
    approval.not_nil!.required_approvals.should contain("write_accounts_opening_compliance_approval")

    subject = approval.not_nil!.subject
    subject.should_not be_nil
    subject.not_nil!.title.should eq("Account Opening")
    subject.not_nil!.summary.should contain("Test Account")
    subject.not_nil!.summary.should contain("checking")
    field_labels = subject.not_nil!.fields.map(&.label)
    field_labels.should contain("Name")
    field_labels.should contain("Type")
    field_labels.should contain("Currencies")
    subject.not_nil!.fields.find { |f| f.label == "Name" }.not_nil!.value.should eq("Test Account")
    subject.not_nil!.fields.find { |f| f.label == "Type" }.not_nil!.value.should eq("checking")
    currencies_value = subject.not_nil!.fields.find { |f| f.label == "Currencies" }.not_nil!.value
    currencies_value.should contain("eur")
    currencies_value.should contain("usd")
  end
end
