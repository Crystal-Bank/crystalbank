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
            "scope_id" UUID NOT NULL,
            "created_at" timestamp NOT NULL,
            "name" varchar NOT NULL,
            "permissions" JSONB NOT NULL,
            "scopes" JSONB NOT NULL,
            "accepted" boolean NOT NULL DEFAULT false
          );
        )

        m << %(CREATE UNIQUE INDEX roles_uuid_idx ON "projections"."roles"(uuid);)

        m.each { |s| @projection_database.exec s }
      end

      # Requested — insert as pending (accepted = false)
      def apply(event : ::Roles::Creation::Events::Requested)
        created_at = event.header.created_at
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        # Build the role aggregate up to the version of the event
        aggregate = ::Roles::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        # Extract attributes to local variables
        name = aggregate.state.name
        permissions = aggregate.state.permissions
        scope_id = aggregate.state.scope_id
        scopes = aggregate.state.scopes

        # Insert the role projection as pending approval
        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."roles" (
                uuid,
                aggregate_version,
                scope_id,
                created_at,
                name,
                permissions,
                scopes,
                accepted
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          ),
            aggregate_id,
            aggregate_version,
            scope_id,
            created_at,
            name,
            permissions.to_json,
            scopes.to_json,
            false
        end
      end

      # Accepted — activate the role
      def apply(event : ::Roles::Creation::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."roles" SET accepted=$1, aggregate_version=$2 WHERE uuid=$3),
            true, aggregate_version, aggregate_id
        end
      end
    end
  end
end
