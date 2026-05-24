module Test::VirtualAccount::Events
  module Opening
    class Requested
      def create(
        aggr_id = UUID.new("00000000-0000-0000-0000-000000000002"),
        parent_account_id = UUID.new("00000000-0000-0000-0000-000000000001"),
        scope_id = UUID.new("00000000-0000-0000-0000-300000000001"),
      ) : VirtualAccounts::Opening::Events::Requested
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        currencies = ["eur", "usd"].map { |c| CrystalBank::Types::Currencies::Supported.parse(c) }
        customer_ids = [UUID.new("00000000-0000-0000-0000-200000000001")]

        VirtualAccounts::Opening::Events::Requested.new(
          actor_id: actor_id,
          aggregate_id: aggr_id,
          name: "Test Virtual Account",
          parent_account_id: parent_account_id,
          currencies: currencies,
          customer_ids: customer_ids,
          scope_id: scope_id,
          command_handler: "test",
          comment: "test comment"
        )
      end

      def json_string : String
        {
          "comment":           "test comment",
          "name":              "Test Virtual Account",
          "parent_account_id": "00000000-0000-0000-0000-000000000001",
          "currencies":        ["eur", "usd"],
          "customer_ids":      ["00000000-0000-0000-0000-200000000001"],
          "scope_id":          "00000000-0000-0000-0000-300000000001",
        }.to_json
      end
    end

    class Accepted
      def create(
        aggr_id = UUID.new("00000000-0000-0000-0000-000000000002"),
      ) : VirtualAccounts::Opening::Events::Accepted
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_version = 2

        VirtualAccounts::Opening::Events::Accepted.new(
          actor_id: actor_id,
          aggregate_id: aggr_id,
          aggregate_version: aggregate_version,
          command_handler: "test",
          comment: "test comment"
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
