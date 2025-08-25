module CrystalBank::Domains::Users
  module Repositories
    class Roles
      struct Role
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def exists!(role_id : UUID)
        fetch!(role_id)
      end

      def fetch!(role_id : UUID) : Role
        @db.query_one("SELECT * FROM projections.roles WHERE uuid = $1", role_id, as: Role)
      rescue DB::NoResultsError
        raise ES::Exception::NotFound.new("Role '#{role_id}' not found")
      end
    end
  end
end
