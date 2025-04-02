module Test::Customer::Events
  module Onboarding
    class Accepted
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : Customers::Onboarding::Events::Accepted
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        aggregate_version = 2
        command_handler = "test"
        comment = "test comment"

        Customers::Onboarding::Events::Accepted.new(
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

    class Requested
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : Customers::Onboarding::Events::Requested
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        customer_type = CrystalBank::Types::Customers::Type.parse("individual")
        aggregate_id = aggr_id
        name = "Peter Pan"
        command_handler = "test"
        comment = "test comment"
        scope_id = UUID.new("00000000-0000-0000-0000-000000000001")

        Customers::Onboarding::Events::Requested.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          name: name,
          scope_id: scope_id,
          type: customer_type,
          command_handler: command_handler,
          comment: comment
        )
      end

      def json_string : String
        {
          "comment":  "test comment",
          "name":     "Peter Pan",
          "scope_id": "00000000-0000-0000-0000-000000000001",
          "type":     "individual",
        }.to_json
      end
    end
  end
end
