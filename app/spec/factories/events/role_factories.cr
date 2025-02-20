module Test::Role::Events
  module Creation
    class Accepted
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : Roles::Creation::Events::Accepted
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        aggregate_version = 2
        command_handler = "test"
        comment = "test comment"

        Roles::Creation::Events::Accepted.new(
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
      def create(aggr_id = UUID.new("00000000-0000-0000-0000-000000000001")) : Roles::Creation::Events::Requested
        actor_id = UUID.new("00000000-0000-0000-0000-000000000000")
        aggregate_id = aggr_id
        name = "Scope name test"
        permissions = [CrystalBank::Permissions::WRITE_roles_creation]
        scopes = [UUID.new("00000000-0000-0000-0000-200000000001")]
        command_handler = "test"
        comment = "test comment"

        Roles::Creation::Events::Requested.new(
          actor_id: actor_id,
          aggregate_id: aggregate_id,
          name: name,
          permissions: permissions,
          scopes: scopes,
          command_handler: command_handler,
          comment: comment
        )
      end

      def json_string : String
        {
          "comment":     "test comment",
          "name":        "Scope name test",
          "permissions": ["write_roles_creation"],
          "scopes":      ["00000000-0000-0000-0000-200000000001"],
        }.to_json
      end
    end
  end
end
