require "../../../../../spec_helper"

module Test::Transactions::InternalTransfers::Events
  module Initiation
    class Accepted
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : ::Transactions::InternalTransfers::Initiation::Events::Accepted
        account_type = CrystalBank::Types::Accounts::Type.parse("checking")
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        aggregate_version = 2
        amount = 100
        command_handler = "test"
        comment = "test comment"
        creditor_account_id = UUID.new("00000000-0000-0000-0000-200000000000")
        currency = CrystalBank::Types::Currencies::Supported.parse("eur")
        debtor_account_id = UUID.new("00000000-0000-0000-0000-100000000000")

        ::Transactions::InternalTransfers::Initiation::Events::Accepted.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          aggregate_version: aggregate_version,
          command_handler: command_handler,
          comment: comment
        )
      end

      def json_string : String
        {
          "comment": "test comment",
        }.to_json
      end
    end
  end
end

describe CrystalBank::Domains::Transactions::InternalTransfers::Initiation::Events::Accepted do
  it "can be initialized" do
    event = Test::Transactions::InternalTransfers::Events::Initiation::Accepted.new.create

    event.header.actor_id.should eq(UUID.new("00000000-0000-0000-0000-000000000000"))
    event.header.aggregate_id.should eq(UUID.new("00000000-0000-0000-0000-000000000001"))
    event.header.aggregate_type.should eq("Transaction")
    event.header.aggregate_version.should eq(2)
    event.header.command_handler.should eq("test")
    event.header.event_handle.should eq("transactions.internal_transfer.initiation.accepted")
    event.body.comment.should eq("test comment")
  end

  it "can be initialized from json" do
    object = Test::Transactions::InternalTransfers::Events::Initiation::Accepted.new
    event = object.create
    h = event.header

    json_body = JSON.parse(object.json_string)

    e = Transactions::InternalTransfers::Initiation::Events::Accepted.new(h, json_body)
    b = e.body.as(Transactions::InternalTransfers::Initiation::Events::Accepted::Body)

    b.comment.should eq("test comment")
  end

  it "can serialize to json" do
    object = Test::Transactions::InternalTransfers::Events::Initiation::Accepted.new
    event = object.create

    b = event.body.as(Transactions::InternalTransfers::Initiation::Events::Accepted::Body)
    b.to_json.should eq(object.json_string)
  end

  it "can serialize and deserialize from json" do
    event = Test::Transactions::InternalTransfers::Events::Initiation::Accepted.new.create
    h = event.header

    b = event.body.as(Transactions::InternalTransfers::Initiation::Events::Accepted::Body)
    json_body = b.to_json

    e = Transactions::InternalTransfers::Initiation::Events::Accepted.new(h, JSON.parse(json_body))
    json_body.should eq(e.body.to_json)
  end
end
