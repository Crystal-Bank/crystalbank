module CrystalBank::Domains::Roles
  module Queries
    class FindRole
      struct Role
        include DB::Serializable
        include DB::Serializable::NonStrict

        @[DB::Field(key: "uuid")]
        getter id : UUID
        getter scope_id : UUID
        getter status : String
        getter name : String

        @[DB::Field(converter: CrystalBank::Converters::GenericArray(CrystalBank::Permissions))]
        getter permissions : Array(CrystalBank::Permissions)

        @[DB::Field(converter: CrystalBank::Converters::UUIDArray)]
        getter scopes : Array(UUID)
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def find!(role_id : UUID) : Role
        @db.query_one(
          %(SELECT * FROM "projections"."roles" WHERE uuid = $1),
          role_id,
          as: Role
        )
      rescue DB::NoResultsError
        raise CrystalBank::Exception::InvalidArgument.new("Role '#{role_id}' not found")
      end
    end
  end
end
