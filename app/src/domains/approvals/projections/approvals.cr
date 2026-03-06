module CrystalBank::Domains::Approvals
  module Projections
    class Approvals < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename = 'approvals');), as: Bool
        return true if skip

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."approvals" (
            "id" SERIAL PRIMARY KEY,
            "uuid" UUID NOT NULL,
            "aggregate_version" int8 NOT NULL,
            "domain_event_handle" varchar NOT NULL,
            "reference_aggregate_id" UUID NOT NULL,
            "scope_id" UUID NOT NULL,
            "requester_id" UUID NOT NULL,
            "approval_permission" varchar NOT NULL,
            "required_approvers" int4 NOT NULL,
            "approval_count" int4 NOT NULL DEFAULT 0,
            "status" varchar NOT NULL DEFAULT 'pending',
            "created_at" timestamp NOT NULL,
            "updated_at" timestamp NOT NULL
          );
        )
        m << %(CREATE UNIQUE INDEX approvals_uuid_idx ON "projections"."approvals"(uuid);)
        m << %(CREATE INDEX approvals_status_idx ON "projections"."approvals"(status);)
        m << %(CREATE INDEX approvals_scope_idx ON "projections"."approvals"(scope_id);)

        m.each { |s| @projection_database.exec s }
      end

      def apply(event : Approvals::Workflow::Events::Initiated)
        aggregate_id = event.header.aggregate_id
        created_at = event.header.created_at

        aggregate = Approvals::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: event.header.aggregate_version)

        s = aggregate.state

        @projection_database.exec %(
          INSERT INTO "projections"."approvals" (
            uuid, aggregate_version, domain_event_handle, reference_aggregate_id,
            scope_id, requester_id, approval_permission, required_approvers,
            approval_count, status, created_at, updated_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $11)
        ),
          aggregate_id,
          event.header.aggregate_version,
          s.domain_event_handle,
          s.reference_aggregate_id,
          s.scope_id,
          s.requester_id,
          s.approval_permission,
          s.required_approvers,
          0,
          "pending",
          created_at
      end

      def apply(event : Approvals::Decision::Events::Made)
        aggregate_id = event.header.aggregate_id

        aggregate = Approvals::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: event.header.aggregate_version)

        @projection_database.exec %(
          UPDATE "projections"."approvals"
          SET approval_count = $1, aggregate_version = $2, updated_at = $3
          WHERE uuid = $4
        ),
          aggregate.state.approval_count,
          event.header.aggregate_version,
          event.header.created_at,
          aggregate_id
      end

      def apply(event : Approvals::Workflow::Events::Completed)
        aggregate_id = event.header.aggregate_id

        aggregate = Approvals::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: event.header.aggregate_version)

        @projection_database.exec %(
          UPDATE "projections"."approvals"
          SET status = $1, aggregate_version = $2, updated_at = $3
          WHERE uuid = $4
        ),
          aggregate.state.status.to_s.downcase,
          event.header.aggregate_version,
          event.header.created_at,
          aggregate_id
      end
    end
  end
end
