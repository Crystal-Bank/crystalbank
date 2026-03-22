require "../../../../../../spec_helper"

describe CrystalBank::Domains::Payments::Sepa::CreditTransfers::Initiation::Commands::ProcessApproval do
  pending "requires event-bus integration: triggered when an Approvals::Collection::Events::Completed event is appended for a SepaCreditTransfer source aggregate" do
    false.should eq(true)
  end
end
