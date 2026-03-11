require "../../../../spec_helper"

# Spec has an issue on a single instance, since the projector is blocked by the sleep/loop in the test

# describe CrystalBank::Domains::Ledger::Transactions::Queries::Postings do
#   it "lists postings from the projection" do
#     uuid = UUID.v7

#     event_1 = Test::Ledger::Transactions::Events::Request::Requested.new.create(aggr_id: uuid)
#     event_2 = Test::Ledger::Transactions::Events::Request::Accepted.new.create(aggr_id: uuid)
#     TEST_EVENT_STORE.append(event_1)
#     TEST_EVENT_STORE.append(event_2)

#     Ledger::Transactions::Projections::Postings.new.apply(event_2)
#     postings = Ledger::Transactions::Queries::Postings.new.list(cursor: nil, limit: 10)
#     transaction_postings = postings.select { |p| p.id == uuid }
#     transaction_postings.size.should eq(2)

#     directions = transaction_postings.map(&.direction)
#     directions.should contain("debit")
#     directions.should contain("credit")

#     transaction_postings.each do |p|
#       p.currency.should eq("eur")
#       p.amount.should eq(10000_i64)
#       p.entry_type.should eq("PRINCIPAL")
#       p.remittance_information.should eq("test remittance information")
#     end
#   end

#   it "paginates with a cursor" do
#     uuid_a = UUID.v7
#     uuid_b = UUID.v7

#     [uuid_a, uuid_b].each do |uuid|
#       event_1 = Test::Ledger::Transactions::Events::Request::Requested.new.create(aggr_id: uuid)
#       event_2 = Test::Ledger::Transactions::Events::Request::Accepted.new.create(aggr_id: uuid)
#       TEST_EVENT_STORE.append(event_1)
#       TEST_EVENT_STORE.append(event_2)
#       Ledger::Transactions::Projections::Postings.new.apply(event_2)
#     end

#     all_postings = Ledger::Transactions::Queries::Postings.new.list(cursor: nil, limit: 100)
#     cursor_uuid = all_postings.map(&.id).uniq!.sort.last

#     paginated = Ledger::Transactions::Queries::Postings.new.list(cursor: cursor_uuid, limit: 10)
#     paginated.all? { |p| p.id >= cursor_uuid }.should be_true
#   end
# end
