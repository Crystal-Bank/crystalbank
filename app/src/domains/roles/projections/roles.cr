module CrystalBank::Domains::Roles
  module Projections
    class Roles < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename  = 'roles');), as: Bool
        return true if skip

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."roles" (
            "id" SERIAL PRIMARY KEY,
            "uuid" UUID NOT NULL,
            "aggregate_version" int8 NOT NULL,
            "created_at" timestamp NOT NULL,
            "name" varchar NOT NULL,
            "permissions" JSONB NOT NULL,
            "scopes" JSONB NOT NULL
          );
        )

        m << %(CREATE UNIQUE INDEX roles_uuid_idx ON "projections"."roles"(uuid);)

        m.each { |s| @projection_database.exec s }
      end

      # Created
      def apply(event : ::Roles::Creation::Events::Accepted)
        # Extract attributes to local variables
        uuid = event.header.event_id
        created_at = event.header.created_at
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        # Build the account aggregate up to the version of the event
        aggregate = ::Roles::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        # Extract attributes to local variables
        name = aggregate.state.name
        permissions = aggregate.state.permissions
        scopes = aggregate.state.scopes

        # Insert the account projection into the projection database
        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."roles" (
                uuid,
                aggregate_version,
                created_at,
                name,
                permissions,
                scopes
              )
              VALUES ($1, $2, $3, $4, $5, $6)
          ),
            aggregate_id,
            aggregate_version,
            created_at,
            name,
            permissions.to_json,
            scopes.to_json
        end
      end
    end
  end
end
