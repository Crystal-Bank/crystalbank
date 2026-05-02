module CrystalBank::Domains::Scopes
  module Projections
    class Scopes < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename  = 'scopes');), as: Bool
        return true if skip

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."scopes" (
            "id" SERIAL PRIMARY KEY,
            "uuid" UUID NOT NULL,
            "aggregate_version" int8 NOT NULL,
            "scope_id" UUID NOT NULL,
            "created_at" timestamp NOT NULL,
            "name" varchar NOT NULL,
            "parent_scope_id" UUID,
            "status" varchar NOT NULL
          );
        )

        m << %(CREATE UNIQUE INDEX scopes_uuid_idx ON "projections"."scopes"(uuid);)

        m.each { |s| @projection_database.exec s }
      end

      # Requested
      def apply(event : ::Scopes::Creation::Events::Requested)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

        body = event.body.as(::Scopes::Creation::Events::Requested::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."scopes" (
                uuid,
                aggregate_version,
                scope_id,
                created_at,
                name,
                parent_scope_id,
                status
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7)
          ),
            aggregate_id,
            aggregate_version,
            body.scope_id,
            created_at,
            body.name,
            body.parent_scope_id,
            "pending_approval"
        end
      end

      # Accepted (name change) — updates the scope's name
      def apply(event : ::Scopes::NameChange::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        body = event.body.as(::Scopes::NameChange::Events::Accepted::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."scopes" SET name=$1, aggregate_version=$2 WHERE uuid=$3),
            body.name,
            aggregate_version,
            aggregate_id
        end
      end

      # Accepted (creation)
      def apply(event : ::Scopes::Creation::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."scopes" SET status=$1, aggregate_version=$2 WHERE uuid=$3),
            "active",
            aggregate_version,
            aggregate_id
        end
      end
    end
  end
end
