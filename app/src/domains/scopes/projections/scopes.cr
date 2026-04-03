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
            "accepted" boolean NOT NULL DEFAULT false
          );
        )

        m << %(CREATE UNIQUE INDEX scopes_uuid_idx ON "projections"."scopes"(uuid);)

        m.each { |s| @projection_database.exec s }
      end

      # Requested — insert as pending (accepted = false)
      def apply(event : ::Scopes::Creation::Events::Requested)
        created_at = event.header.created_at
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        # Build the scope aggregate up to the version of the event
        aggregate = ::Scopes::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        # Extract attributes to local variables
        name = aggregate.state.name
        parent_scope_id = aggregate.state.parent_scope_id
        scope_id = aggregate.state.scope_id

        # Insert the scope projection as pending approval
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
                accepted
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7)
          ),
            aggregate_id,
            aggregate_version,
            scope_id,
            created_at,
            name,
            parent_scope_id,
            false
        end
      end

      # Accepted — activate the scope
      def apply(event : ::Scopes::Creation::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."scopes" SET accepted=$1, aggregate_version=$2 WHERE uuid=$3),
            true, aggregate_version, aggregate_id
        end
      end
    end
  end
end
