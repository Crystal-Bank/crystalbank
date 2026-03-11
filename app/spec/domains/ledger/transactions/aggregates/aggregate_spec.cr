require "../../../../spec_helper"

describe CrystalBank::Domains::Ledger::Transactions::Aggregate do
  it "can be initialized" do
    uuid = UUID.v7
    aggr = CrystalBank::Domains::Ledger::Transactions::Aggregate.new(uuid)

    aggr.state.aggregate_id.should eq(uuid)
    aggr.state.aggregate_type.should eq("Ledger.Transaction")
    aggr.state.aggregate_version.should eq(0)

    aggr.state.currency.should eq(nil)
    aggr.state.entries.should eq(nil)
    aggr.state.posting_date.should eq(nil)
    aggr.state.value_date.should eq(nil)
    aggr.state.remittance_information.should eq(nil)
    aggr.state.payment_type.should eq(nil)
    aggr.state.external_ref.should eq(nil)
    aggr.state.channel.should eq(nil)
    aggr.state.internal_note.should eq(nil)
    aggr.state.scope_id.should eq(nil)
  end
end
