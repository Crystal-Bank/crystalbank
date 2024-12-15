module CrystalBank::Domains::ApiKeys
  module Repositories
    class Users
      struct User
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def exists!(user_id : UUID)
        fetch(user_id, scopes)
      end

      def fetch!(user_id : UUID) : User
        @db.query_one("SELECT * FROM projections.users WHERE uuid = $1", user_id, as: User)
      rescue DB::NoResultsError
        raise ES::Exception::NotFound.new("User '#{user_id}' not found")
      end
    end
  end
end
