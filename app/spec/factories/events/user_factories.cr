module Test::User::Events
  module Onboarding
    class Accepted
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : Users::Onboarding::Events::Accepted
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        aggregate_version = 2
        command_handler = "test"
        comment = "test comment"

        Users::Onboarding::Events::Accepted.new(
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
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : Users::Onboarding::Events::Requested
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        name = "Peter Pan"
        email = "test@crystalbank.xyz"
        command_handler = "test"
        comment = "test comment"

        Users::Onboarding::Events::Requested.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          name: name,
          email: email,
          command_handler: command_handler,
          comment: comment
        )
      end

      def json_string : String
        {
          "comment": "test comment",
          "name":    "Peter Pan",
          "email":   "test@crystalbank.xyz",
        }.to_json
      end
    end
  end
end
