module CrystalBank::Domains::Roles
  module Projections
    class Roles < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename  = 'roles');), as: Bool

        unless skip
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
              "status" varchar NOT NULL,
              "pending_permissions" JSONB
            );
          )
          m << %(CREATE UNIQUE INDEX roles_uuid_idx ON "projections"."roles"(uuid);)
          m.each { |s| @projection_database.exec s }
        end

        # Add pending_permissions column to existing tables (idempotent migration)
        has_column = @projection_database.query_one %(
          SELECT EXISTS (
            SELECT FROM information_schema.columns
            WHERE table_schema = 'projections'
              AND table_name   = 'roles'
              AND column_name  = 'pending_permissions'
          );
        ), as: Bool
        @projection_database.exec %(ALTER TABLE "projections"."roles" ADD COLUMN "pending_permissions" JSONB) unless has_column
      end

      # Requested (creation)
      def apply(event : ::Roles::Creation::Events::Requested)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

        body = event.body.as(::Roles::Creation::Events::Requested::Body)

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
                status
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          ),
            aggregate_id,
            aggregate_version,
            body.scope_id,
            created_at,
            body.name,
            body.permissions.to_json,
            body.scopes.to_json,
            "pending_approval"
        end
      end

      # Accepted (creation)
      def apply(event : ::Roles::Creation::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."roles" SET status=$1, aggregate_version=$2 WHERE uuid=$3),
            "active",
            aggregate_version,
            aggregate_id
        end
      end

      # Requested (permissions update) — records the desired permissions as pending
      def apply(event : ::Roles::PermissionsUpdate::Events::Requested)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        body = event.body.as(::Roles::PermissionsUpdate::Events::Requested::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."roles" SET pending_permissions=$1, aggregate_version=$2 WHERE uuid=$3),
            body.permissions.to_json,
            aggregate_version,
            aggregate_id
        end
      end

      # Accepted (permissions update) — applies the approved permissions and clears the pending state
      def apply(event : ::Roles::PermissionsUpdate::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        body = event.body.as(::Roles::PermissionsUpdate::Events::Accepted::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."roles" SET permissions=$1, pending_permissions=NULL, aggregate_version=$2 WHERE uuid=$3),
            body.permissions.to_json,
            aggregate_version,
            aggregate_id
        end
      end
    end
  end
end
