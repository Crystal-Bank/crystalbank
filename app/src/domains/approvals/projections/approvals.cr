module CrystalBank::Domains::Approvals
  module Projections
    class Approvals < ES::Projection
      include ES::ProjectionDSL

      define_projection "projections.approvals", init: true do
        column :id, Int32, serial: true, primary_key: true
        column :uuid, UUID, null: false
        column :aggregate_version, int8, null: false
        column :scope_id, UUID, null: false
        column :source_aggregate_type, String, null: false
        column :source_aggregate_id, UUID, null: false
        column :required_approvals, JSON, null: false
        column :requestor_id, UUID, null: true
        column :collected_approvals, JSON, null: false, default: "[]"
        column :completed, Bool, null: false, default: false
        column :rejected, Bool, null: false, default: false
        column :subject, JSON, null: true
        column :rejection_reason, String, null: true
        column :created_at, Time, null: false
        column :updated_at, Time, null: false

        index [:uuid], unique: true, name: "approvals_uuid_idx"
        index [:source_aggregate_type, :source_aggregate_id], name: "approvals_source_idx"
      end

      apply(::Approvals::Creation::Events::Requested) do
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

        body = event.body.as(::Approvals::Creation::Events::Requested::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."approvals" (
                uuid,
                aggregate_version,
                scope_id,
                source_aggregate_type,
                source_aggregate_id,
                requestor_id,
                required_approvals,
                collected_approvals,
                completed,
                subject,
                created_at,
                updated_at
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $11)
          ),
            aggregate_id,
            aggregate_version,
            body.scope_id,
            body.source_aggregate_type,
            body.source_aggregate_id,
            event.header.actor_id,
            body.required_approvals.to_json,
            "[]",
            false,
            body.subject.try(&.to_json),
            created_at
        end
      end

      apply(::Approvals::Collection::Events::Collected) do
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        updated_at = event.header.created_at

        body = event.body.as(::Approvals::Collection::Events::Collected::Body)
        new_entry = {user_id: body.user_id, permissions: body.permissions, comment: body.comment}.to_json

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE "projections"."approvals"
            SET
              "aggregate_version" = $1,
              "collected_approvals" = "collected_approvals" || $2::jsonb,
              "updated_at" = $3
            WHERE "uuid" = $4
          ),
            aggregate_version,
            new_entry,
            updated_at,
            aggregate_id
        end
      end

      apply(::Approvals::Collection::Events::Completed) do
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        updated_at = event.header.created_at

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE "projections"."approvals"
            SET
              "aggregate_version" = $1,
              "completed" = true,
              "updated_at" = $2
            WHERE "uuid" = $3
          ),
            aggregate_version,
            updated_at,
            aggregate_id
        end
      end

      apply(::Approvals::Rejection::Events::Rejected) do
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        updated_at = event.header.created_at

        body = event.body.as(::Approvals::Rejection::Events::Rejected::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE "projections"."approvals"
            SET
              "aggregate_version" = $1,
              "rejected" = true,
              "rejection_reason" = $2,
              "updated_at" = $3
            WHERE "uuid" = $4
          ),
            aggregate_version,
            body.comment.try { |c| c.empty? ? nil : c },
            updated_at,
            aggregate_id
        end
      end
    end
  end
end
