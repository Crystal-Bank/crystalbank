module Test::Account::Events
  module Opening
    class Accepted
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : Accounts::Opening::Events::Accepted
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        aggregate_version = 2
        command_handler = "test"
        comment = "test comment"

        Accounts::Opening::Events::Accepted.new(
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
