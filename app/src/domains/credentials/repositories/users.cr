module CrystalBank::Domains::Credentials
  module Repositories
    class Users
      struct User
        include DB::Serializable
        include DB::Serializable::NonStrict

        @[DB::Field(key: "uuid")]
        getter id : UUID
        getter name : String
        getter email : String
        getter status : String

        @[DB::Field(key: "role_ids", converter: CrystalBank::Converters::UUIDArray)]
        getter role_ids = Array(UUID).new
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def fetch!(user_id : UUID) : User
        @db.query_one("SELECT * FROM projections.users WHERE uuid = $1", user_id, as: User)
      rescue DB::NoResultsError
        raise ES::Exception::NotFound.new("User '#{user_id}' not found")
      end

      def fetch_by_email!(email : String) : User
        @db.query_one(
          "SELECT * FROM projections.users WHERE LOWER(email) = LOWER($1) AND status = 'active'",
          email,
          as: User
        )
      rescue DB::NoResultsError
        raise CrystalBank::Exception::Authentication.new("Invalid login credentials", HTTP::Status::UNAUTHORIZED)
      end
    end
  end
end
