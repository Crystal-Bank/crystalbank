module Test::ApiKey::Events
  module Generation
    class Accepted
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : ApiKeys::Generation::Events::Accepted
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        aggregate_version = 2
        command_handler = "test"
        comment = "test comment"

        ApiKeys::Generation::Events::Accepted.new(
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
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : ApiKeys::Generation::Events::Requested
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        api_secret = "api_secret"
        command_handler = "test"
        comment = "test comment"
        name = "test name"
        scope_id = UUID.new("00000000-0000-0000-0000-000000000001")
        user_id = UUID.new("00000000-0000-0000-0000-000000000000")

        ApiKeys::Generation::Events::Requested.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          api_secret: api_secret,
          command_handler: command_handler,
          comment: comment,
          name: name,
          scope_id: scope_id,
          user_id: user_id
        )
      end

      def json_string : String
        {
          "comment":    "test comment",
          "api_secret": "api_secret",
          "name":       "test name",
          "scope_id":   "00000000-0000-0000-0000-000000000001",
          "user_id":    "00000000-0000-0000-0000-000000000000",
        }.to_json
      end
    end
  end

  module Revocation
    class Accepted
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001"), version = 1) : ApiKeys::Revocation::Events::Accepted
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        aggregate_version = version
        command_handler = "test"
        comment = "test comment"

        ApiKeys::Revocation::Events::Accepted.new(
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
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001"), version = 2) : ApiKeys::Revocation::Events::Requested
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        aggregate_version = version
        reason = "revocation reason"
        command_handler = "test"
        comment = "test comment"

        ApiKeys::Revocation::Events::Requested.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          aggregate_version: aggregate_version,
          command_handler: command_handler,
          comment: comment,
          reason: reason
        )
      end

      def json_string : String
        {
          "comment": "test comment",
          "reason":  "revocation reason",
        }.to_json
      end
    end
  end
end
