module Test::Scope::Events
  module Creation
    class Accepted
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : Scopes::Creation::Events::Accepted
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        aggregate_version = 2
        command_handler = "test"
        comment = "test comment"

        Scopes::Creation::Events::Accepted.new(
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
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : Scopes::Creation::Events::Requested
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        name = "Scope name test"
        parent_scope_id = UUID.new("00000000-0000-0000-0000-200000000001")
        scope_id = UUID.new("00000000-0000-0000-0000-100000000001")
        command_handler = "test"
        comment = "test comment"

        Scopes::Creation::Events::Requested.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          name: name,
          parent_scope_id: parent_scope_id,
          scope_id: scope_id,
          command_handler: command_handler,
          comment: comment
        )
      end

      def json_string : String
        {
          "comment":         "test comment",
          "name":            "Scope name test",
          "parent_scope_id": "00000000-0000-0000-0000-200000000001",
          "scope_id":        "00000000-0000-0000-0000-100000000001",
        }.to_json
      end
    end
  end
end
