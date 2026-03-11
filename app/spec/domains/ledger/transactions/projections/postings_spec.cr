require "../../../../spec_helper"
require "../events/request/accepted_spec"
require "../events/request/requested_spec"

describe CrystalBank::Domains::Ledger::Transactions::Projections::Postings do
  it "correctly applies 'Ledger::Transactions::Request::Events::Accepted' event" do
    projection = Ledger::Transactions::Projections::Postings.new
    uuid = UUID.v7

    event_1 = Test::Ledger::Transactions::Events::Request::Requested.new.create(aggr_id: uuid)
    event_2 = Test::Ledger::Transactions::Events::Request::Accepted.new.create(aggr_id: uuid)
    TEST_EVENT_STORE.append(event_1)
    TEST_EVENT_STORE.append(event_2)

    projection.apply(event_2)

    count = TEST_PROJECTION_DB.scalar(%(SELECT count(*) FROM "projections"."postings" WHERE transaction_id = $1), uuid)
    count.should eq(2)
  end
end
