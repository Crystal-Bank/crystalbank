module CrystalBank::Domains::Transactions::Postings
  module Queries
    class Postings
      struct Posting
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        @[DB::Field(key: "uuid")]
        getter id : UUID
        getter object : String = "posting"

        getter account_id : UUID
        getter amount : Int64
        getter creditor_account_id : UUID
        getter debtor_account_id : UUID
        getter remittance_information : String
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def call : Array(Posting)
        list
      end

      private def list : Array(Posting)
        @db.query_all(%(SELECT * FROM "projections"."postings"), as: Posting)
      end
    end
  end
end
