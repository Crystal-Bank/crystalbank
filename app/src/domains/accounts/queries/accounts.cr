module CrystalBank::Domains::Accounts
  module Queries
    class Accounts
      struct Account
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID
        getter object : String = "account"

        getter currencies = Array(CrystalBank::Types::Currencies::Supported).new

        getter type : CrystalBank::Types::Accounts::Type
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def call : Array(Account)
        list
      end

      private def list : Array(Account)
        @db.query_all(%(SELECT * FROM "projections"."accounts"), as: Account)
      end
    end
  end
end
