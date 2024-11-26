require "../../../../spec_helper"

module Test::Account::Events
  module Opening
    class Requested
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : Accounts::Opening::Events::Requested
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        account_type = CrystalBank::Types::Accounts::Type.parse("checking")
        aggregate_id = aggr_id
        currencies = ["eur", "usd"].map { |c| CrystalBank::Types::Currencies::Supported.parse(c) }
        customer_ids = [UUID.new("00000000-0000-0000-0000-200000000001"), UUID.new("00000000-0000-0000-0000-200000000002")]
        command_handler = "test"
        comment = "test comment"

        Accounts::Opening::Events::Requested.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          currencies: currencies,
          customer_ids: customer_ids,
          type: account_type,
          command_handler: command_handler,
          comment: comment
        )
      end

      def json_string : String
        {
          "comment":      "test comment",
          "currencies":   ["eur", "usd"],
          "customer_ids": ["00000000-0000-0000-0000-200000000001", "00000000-0000-0000-0000-200000000002"],
          "type":         "checking",
        }.to_json
      end
    end
  end
end

describe CrystalBank::Domains::Accounts::Opening::Events::Requested do
  it "can be initialized" do
    event = Test::Account::Events::Opening::Requested.new.create

    event.header.actor_id.should eq(UUID.new("00000000-0000-0000-0000-000000000000"))
    event.header.aggregate_id.should eq(UUID.new("00000000-0000-0000-0000-000000000001"))
    event.header.aggregate_type.should eq("Account")
    event.header.aggregate_version.should eq(1)
    event.header.command_handler.should eq("test")
    event.header.event_handle.should eq("account.opening.requested")
    event.body.comment.should eq("test comment")
  end

  it "can be initialized from json" do
    object = Test::Account::Events::Opening::Requested.new
    event = object.create
    h = event.header

    json_body = JSON.parse(object.json_string)

    e = Accounts::Opening::Events::Requested.new(h, json_body)
    b = e.body.as(Accounts::Opening::Events::Requested::Body)

    b.comment.should eq("test comment")
  end

  it "can serialize to json" do
    object = Test::Account::Events::Opening::Requested.new
    event = object.create

    b = event.body.as(Accounts::Opening::Events::Requested::Body)
    b.to_json.should eq(object.json_string)
  end

  it "can serialize and deserialize from json" do
    event = Test::Account::Events::Opening::Requested.new.create
    h = event.header

    b = event.body.as(Accounts::Opening::Events::Requested::Body)
    json_body = b.to_json

    e = Accounts::Opening::Events::Requested.new(h, JSON.parse(json_body))
    json_body.should eq(e.body.to_json)
  end
end
