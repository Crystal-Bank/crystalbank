module CrystalBank::Domains::Scopes
  module Projections
    class ScopesNameChanges < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename = 'scopes_name_changes');), as: Bool
        return true if skip

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."scopes_name_changes" (
            "id" SERIAL PRIMARY KEY,
            "uuid" UUID NOT NULL,
            "aggregate_version" int8 NOT NULL,
            "scope_id" UUID NOT NULL,
            "created_at" timestamp NOT NULL,
            "name" varchar NOT NULL,
            "status" varchar NOT NULL
          );
        )

        m << %(CREATE UNIQUE INDEX scopes_name_changes_uuid_idx ON "projections"."scopes_name_changes"(uuid);)
        m << %(CREATE INDEX scopes_name_changes_scope_id_idx ON "projections"."scopes_name_changes"(scope_id);)

        m.each { |s| @projection_database.exec s }
      end

      # Requested — insert a new name change request as pending approval
      def apply(event : ::Scopes::NameChange::Events::Requested)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

        body = event.body.as(::Scopes::NameChange::Events::Requested::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."scopes_name_changes" (
                uuid,
                aggregate_version,
                scope_id,
                created_at,
                name,
                status
              )
              VALUES ($1, $2, $3, $4, $5, $6)
          ),
            aggregate_id,
            aggregate_version,
            body.scope_id,
            created_at,
            body.name,
            "pending_approval"
        end
      end

      # Completed — mark the name change request as completed
      def apply(event : ::Scopes::NameChange::Events::Completed)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."scopes_name_changes" SET status=$1, aggregate_version=$2 WHERE uuid=$3),
            "completed",
            aggregate_version,
            aggregate_id
        end
      end
    end
  end
end
