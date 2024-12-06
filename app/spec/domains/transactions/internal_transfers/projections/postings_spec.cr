require "../../../../spec_helper"

describe CrystalBank::Domains::Transactions::InternalTransfers::Projections::Postings do
  it "correctly applies 'Transactions::InternalTransfers::Initiation::Events::Accepted' event" do
    projection = Transactions::InternalTransfers::Projections::Postings.new
    uuid = UUID.v7

    event_1 = Test::Transactions::InternalTransfers::Events::Initiation::Requested.new.create(aggr_id: uuid)
    event_2 = Test::Transactions::InternalTransfers::Events::Initiation::Accepted.new.create(aggr_id: uuid)
    TEST_EVENT_STORE.append(event_1)
    TEST_EVENT_STORE.append(event_2)

    projection.apply(event_2)

    count = TEST_PROJECTION_DB.scalar(%(SELECT count(*) FROM "projections"."postings" WHERE uuid = $1), uuid)
    count.should eq(2)
  end
end
