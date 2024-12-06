require "../../../../spec_helper"

describe CrystalBank::Domains::Transactions::InternalTransfers::Aggregate do
  it "can be initialized" do
    uuid = UUID.v7
    aggr = CrystalBank::Domains::Transactions::InternalTransfers::Aggregate.new(uuid)

    aggr.state.aggregate_id.should eq(uuid)
    aggr.state.aggregate_type.should eq("Transactions.InternalTransfer")
    aggr.state.aggregate_version.should eq(0)

    aggr.state.account_id.should eq(nil)
    aggr.state.amount.should eq(nil)
    aggr.state.creditor_account_id.should eq(nil)
    aggr.state.currency.should eq(nil)
    aggr.state.debtor_account_id.should eq(nil)
    aggr.state.remittance_information.should eq(nil)
  end
end
