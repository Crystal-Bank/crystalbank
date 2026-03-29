module CrystalBank::Domains::Accounts
  module Projections
    class AccountBlocks < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename = 'account_blocks');), as: Bool
        return true if skip

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."account_blocks" (
            "id" SERIAL PRIMARY KEY,
            "account_uuid" UUID NOT NULL,
            "block_type" varchar NOT NULL,
            "applied_at" timestamp NOT NULL,
            "applied_by" UUID,
            "reason" varchar,
            "removed_at" timestamp,
            "removed_by" UUID,
            UNIQUE ("account_uuid", "block_type")
          );
        )

        m << %(CREATE INDEX account_blocks_account_uuid_idx ON "projections"."account_blocks"(account_uuid);)

        m.each { |s| @projection_database.exec s }
      end

      # Block applied to account
      def apply(event : ::Accounts::Blocking::Events::Applied)
        account_uuid = event.header.aggregate_id
        applied_at = event.header.created_at
        applied_by = event.header.actor_id

        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        aggregate = ::Accounts::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        body = event.body.as(::Accounts::Blocking::Events::Applied::Body)
        block_type = body.block_type.to_s
        reason = body.reason

        @projection_database.exec %(
          INSERT INTO "projections"."account_blocks" (
            account_uuid, block_type, applied_at, applied_by, reason
          ) VALUES ($1, $2, $3, $4, $5)
          ON CONFLICT (account_uuid, block_type) DO UPDATE
            SET applied_at = EXCLUDED.applied_at,
                applied_by = EXCLUDED.applied_by,
                reason = EXCLUDED.reason,
                removed_at = NULL,
                removed_by = NULL
        ),
          account_uuid,
          block_type,
          applied_at,
          applied_by,
          reason
      end

      # Block removed from account
      def apply(event : ::Accounts::Blocking::Events::Removed)
        account_uuid = event.header.aggregate_id
        removed_at = event.header.created_at
        removed_by = event.header.actor_id

        body = event.body.as(::Accounts::Blocking::Events::Removed::Body)
        block_type = body.block_type.to_s

        @projection_database.exec %(
          UPDATE "projections"."account_blocks"
          SET removed_at = $1, removed_by = $2
          WHERE account_uuid = $3 AND block_type = $4 AND removed_at IS NULL
        ),
          removed_at,
          removed_by,
          account_uuid,
          block_type
      end
    end
  end
end
