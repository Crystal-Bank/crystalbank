require "../../../../spec_helper"

module Test::Customer::Events
  module Onboarding
    class Requested
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")): Customers::Onboarding::Events::Requested
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        customer_type = CrystalBank::Types::Customers::Type.parse("individual")
        aggregate_id = aggr_id
        name = "Peter Pan"
        command_handler = "test"
        comment = "test comment"

        Customers::Onboarding::Events::Requested.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          name: name,
          type: customer_type,
          command_handler: command_handler,
          comment: comment
        )
      end

      def json_string : String
        {
          "comment": "test comment",
          "name":    "Peter Pan",
          "type":    "individual",
        }.to_json
      end
    end
  end
end

describe CrystalBank::Domains::Customers::Onboarding::Events::Requested do
  it "can be initialized" do
    event = Test::Customer::Events::Onboarding::Requested.new.create

    event.header.actor_id.should eq(UUID.new("00000000-0000-0000-0000-000000000000"))
    event.header.aggregate_id.should eq(UUID.new("00000000-0000-0000-0000-000000000001"))
    event.header.aggregate_type.should eq("Customer")
    event.header.aggregate_version.should eq(1)
    event.header.command_handler.should eq("test")
    event.header.event_handle.should eq("customer.onboarding.requested")
    event.body.comment.should eq("test comment")
  end

  it "can be initialized from json" do
    object = Test::Customer::Events::Onboarding::Requested.new
    event = object.create
    h = event.header

    json_body = JSON.parse(object.json_string)

    e = Customers::Onboarding::Events::Requested.new(h, json_body)
    b = e.body.as(Customers::Onboarding::Events::Requested::Body)

    b.comment.should eq("test comment")
  end

  it "can serialize to json" do
    object = Test::Customer::Events::Onboarding::Requested.new
    event = object.create

    b = event.body.as(Customers::Onboarding::Events::Requested::Body)
    b.to_json.should eq(object.json_string)
  end

  it "can serialize and deserialize from json" do
    event = Test::Customer::Events::Onboarding::Requested.new.create
    h = event.header

    b = event.body.as(Customers::Onboarding::Events::Requested::Body)
    json_body = b.to_json

    e = Customers::Onboarding::Events::Requested.new(h, JSON.parse(json_body))
    json_body.should eq(e.body.to_json)
  end
end
