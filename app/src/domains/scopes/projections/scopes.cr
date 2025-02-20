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
            "created_at" timestamp NOT NULL,
            "name" varchar NOT NULL,
            "parent_scope_id" UUID
          );
        )

        m << %(CREATE UNIQUE INDEX scopes_uuid_idx ON "projections"."scopes"(uuid);)

        m.each { |s| @projection_database.exec s }
      end

      # Created
      def apply(event : ::Scopes::Creation::Events::Accepted)
        # Extract attributes to local variables
        uuid = event.header.event_id
        created_at = event.header.created_at
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        # Build the account aggregate up to the version of the event
        aggregate = ::Scopes::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        # Extract attributes to local variables
        name = aggregate.state.name
        parent_scope_id = aggregate.state.parent_scope_id

        # Insert the account projection into the projection database
        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."scopes" (
                uuid,
                aggregate_version,
                created_at,
                name,
                parent_scope_id
              )
              VALUES ($1, $2, $3, $4, $5)
          ),
            aggregate_id,
            aggregate_version,
            created_at,
            name,
            parent_scope_id
        end
      end
    end
  end
end
