module Test::Approval::Events
  module Creation
    class Requested
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : Approvals::Creation::Events::Requested
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        scope_id = UUID.new("00000000-0000-0000-0000-100000000001")
        source_aggregate_type = "Account"
        source_aggregate_id = UUID.new("00000000-0000-0000-0000-200000000001")
        required_approvals = [
          "write_accounts_opening_compliance_approval",
          "write_accounts_opening_board_approval",
        ]
        command_handler = "test"
        comment = "test comment"

        Approvals::Creation::Events::Requested.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          command_handler: command_handler,
          scope_id: scope_id,
          source_aggregate_type: source_aggregate_type,
          source_aggregate_id: source_aggregate_id,
          required_approvals: required_approvals,
          comment: comment
        )
      end

      def json_string : String
        {
          "comment":               "test comment",
          "scope_id":              "00000000-0000-0000-0000-100000000001",
          "source_aggregate_type": "Account",
          "source_aggregate_id":   "00000000-0000-0000-0000-200000000001",
          "required_approvals":    ["write_accounts_opening_compliance_approval", "write_accounts_opening_board_approval"],
        }.to_json
      end
    end
  end

  module Collection
    class Collected
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : Approvals::Collection::Events::Collected
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        aggregate_version = 2
        user_id = UUID.new("00000000-0000-0000-0000-300000000001")
        permissions = ["write_accounts_opening_compliance_approval"]
        command_handler = "test"
        comment = "test comment"

        Approvals::Collection::Events::Collected.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          aggregate_version: aggregate_version,
          command_handler: command_handler,
          user_id: user_id,
          permissions: permissions,
          comment: comment
        )
      end

      def json_string : String
        {
          "comment":    "test comment",
          "user_id":    "00000000-0000-0000-0000-300000000001",
          "permissions": ["write_accounts_opening_compliance_approval"],
        }.to_json
      end
    end

    class Completed
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : Approvals::Collection::Events::Completed
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        aggregate_version = 3
        command_handler = "test"
        comment = "test comment"

        Approvals::Collection::Events::Completed.new(
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
