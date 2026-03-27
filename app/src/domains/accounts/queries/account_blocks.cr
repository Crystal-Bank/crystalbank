module CrystalBank::Domains::Accounts
  module Queries
    class AccountBlocks
      struct AccountBlock
        include DB::Serializable
        include DB::Serializable::NonStrict
        include JSON::Serializable

        getter account_uuid : UUID
        getter block_type : String
        getter applied_at : Time
        getter applied_by : UUID
        getter reason : String?
        getter removed_at : Time?
        getter removed_by : UUID?

        def block_type_enum : CrystalBank::Types::Accounts::BlockType
          CrystalBank::Types::Accounts::BlockType.parse(block_type)
        end
      end

      def initialize
        @db = ES::Config.projection_database
      end

      def list_active(account_uuid : UUID) : Array(AccountBlock)
        @db.query_all(
          %(SELECT * FROM "projections"."account_blocks" WHERE "account_uuid" = $1 AND "removed_at" IS NULL ORDER BY "applied_at" ASC),
          account_uuid,
          as: AccountBlock
        )
      end

      def list_all(account_uuid : UUID) : Array(AccountBlock)
        @db.query_all(
          %(SELECT * FROM "projections"."account_blocks" WHERE "account_uuid" = $1 ORDER BY "applied_at" ASC),
          account_uuid,
          as: AccountBlock
        )
      end
    end
  end
end
