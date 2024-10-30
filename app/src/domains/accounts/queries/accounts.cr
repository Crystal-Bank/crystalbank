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

        @[DB::Field(converter: CrystalBank::Converters::CurrencyArray)]
        getter currencies = Array(CrystalBank::Types::Currency).new

        getter type : String
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
