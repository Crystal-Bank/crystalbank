module CrystalBank::Domains::Approvals
  module Projections
    class Approvals < ES::Projection
      def prepare
        skip = @projection_database.query_one %(
          SELECT EXISTS (
            SELECT FROM pg_tables
            WHERE schemaname = 'projections' AND tablename = 'approvals'
          );
        ), as: Bool
        return true if skip

        m = Array(String).new

        m << %(
          CREATE TABLE "projections"."approvals" (
            "id"                    SERIAL PRIMARY KEY,
            "uuid"                  UUID NOT NULL,
            "aggregate_version"     int8 NOT NULL,
            "reference_aggregate_id" UUID NOT NULL,
            "reference_type"        varchar NOT NULL,
            "scope_id"              UUID NOT NULL,
            "required_approvals"    jsonb NOT NULL,
            "submitted_steps"       jsonb NOT NULL DEFAULT '[]',
            "status"                varchar NOT NULL DEFAULT 'pending',
            "created_at"            timestamp NOT NULL,
            "updated_at"            timestamp NOT NULL
          );
        )

        m << %(CREATE UNIQUE INDEX approvals_uuid_idx ON "projections"."approvals"(uuid);)
        m << %(CREATE INDEX approvals_reference_idx ON "projections"."approvals"(reference_aggregate_id);)
        m << %(CREATE INDEX approvals_status_idx ON "projections"."approvals"(status);)

        m.each { |s| @projection_database.exec s }
      end

      # Insert row on creation
      def apply(event : ::Approvals::Creation::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        aggregate = ::Approvals::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO "projections"."approvals" (
              uuid, aggregate_version, reference_aggregate_id, reference_type,
              scope_id, required_approvals, submitted_steps, status,
              created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $9)
          ),
            aggregate_id,
            aggregate_version,
            aggregate.state.reference_aggregate_id,
            aggregate.state.reference_type,
            aggregate.state.scope_id,
            aggregate.state.required_approvals.to_json,
            aggregate.state.submitted_steps.to_json,
            aggregate.state.status.to_s.downcase,
            event.header.created_at
        end
      end

      # Update submitted_steps on each accepted submission
      def apply(event : ::Approvals::Submission::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        aggregate = ::Approvals::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE "projections"."approvals"
            SET submitted_steps = $1, aggregate_version = $2, updated_at = $3
            WHERE uuid = $4
          ),
            aggregate.state.submitted_steps.to_json,
            aggregate_version,
            event.header.created_at,
            aggregate_id
        end
      end

      # Mark as approved
      def apply(event : ::Approvals::Submission::Events::AllApproved)
        aggregate_id = event.header.aggregate_id

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE "projections"."approvals"
            SET status = 'approved', aggregate_version = $1, updated_at = $2
            WHERE uuid = $3
          ),
            event.header.aggregate_version,
            event.header.created_at,
            aggregate_id
        end
      end

      # Mark as rejected
      def apply(event : ::Approvals::Submission::Events::Rejected)
        aggregate_id = event.header.aggregate_id

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE "projections"."approvals"
            SET status = 'rejected', aggregate_version = $1, updated_at = $2
            WHERE uuid = $3
          ),
            event.header.aggregate_version,
            event.header.created_at,
            aggregate_id
        end
      end
    end
  end
end
