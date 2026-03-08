module CrystalBank::Domains::Approvals
  module Projections
    class Approvals < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename  = 'approvals');), as: Bool
        return true if skip

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."approvals" (
            "id" SERIAL PRIMARY KEY,
            "uuid" UUID NOT NULL,
            "aggregate_version" int8 NOT NULL,
            "scope_id" UUID NOT NULL,
            "source_aggregate_type" varchar NOT NULL,
            "source_aggregate_id" UUID NOT NULL,
            "required_approvals" JSONB NOT NULL,
            "requestor_id" UUID,
            "collected_approvals" JSONB NOT NULL DEFAULT '[]'::jsonb,
            "completed" boolean NOT NULL DEFAULT false,
            "created_at" timestamp NOT NULL,
            "updated_at" timestamp NOT NULL
          );
        )

        m << %(CREATE UNIQUE INDEX approvals_uuid_idx ON "projections"."approvals"(uuid);)
        m << %(CREATE INDEX approvals_source_idx ON "projections"."approvals"(source_aggregate_type, source_aggregate_id);)

        m.each { |s| @projection_database.exec s }
      end

      # Created
      def apply(event : ::Approvals::Creation::Events::Requested)
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
                created_at,
                updated_at
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $10)
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
            created_at
        end
      end

      # Collected
      def apply(event : ::Approvals::Collection::Events::Collected)
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

      # Completed
      def apply(event : ::Approvals::Collection::Events::Completed)
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
    end
  end
end
