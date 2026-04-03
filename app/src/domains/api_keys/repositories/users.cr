module CrystalBank::Domains::ApiKeys
  module Repositories
    class Users
      struct User
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID

        @[DB::Field(key: "role_ids", converter: CrystalBank::Converters::UUIDArray)]
        getter role_ids = Array(UUID).new
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def fetch!(user_id : UUID) : User
        @db.query_one("SELECT * FROM projections.users WHERE uuid = $1 AND status = 'active'", user_id, as: User)
      rescue DB::NoResultsError
        raise ES::Exception::NotFound.new("User '#{user_id}' not found")
      end
    end
  end
end
