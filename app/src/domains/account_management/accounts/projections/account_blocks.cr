module CrystalBank::Domains::Accounts
  module Projections
    class AccountBlocks < ES::Projection
      include ES::ProjectionDSL

      define_projection "projections.account_blocks", init: true do
        column :id, Int32, serial: true, primary_key: true
        column :account_uuid, UUID, null: false
        column :block_type, String, null: false
        column :applied_at, Time, null: false
        column :applied_by, UUID, null: true
        column :reason, String, null: true
        column :removed_at, Time, null: true
        column :removed_by, UUID, null: true

        index [:account_uuid], name: "account_blocks_account_uuid_idx"
        index [:account_uuid, :block_type], unique: true, name: "account_blocks_account_uuid_block_type_idx"
      end

      apply(::Accounts::Blocking::Events::Applied) do
        account_uuid = event.header.aggregate_id
        applied_at = event.header.created_at
        applied_by = event.header.actor_id

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

      apply(::Accounts::Blocking::Events::Removed) do
        account_uuid = event.header.aggregate_id
        removed_at = event.header.created_at
        removed_by = event.header.actor_id

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
