module CrystalBank::Domains::Roles
  module Projections
    class RolesPermissionsUpdates < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename = 'roles_permissions_updates');), as: Bool
        return true if skip

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."roles_permissions_updates" (
            "id" SERIAL PRIMARY KEY,
            "uuid" UUID NOT NULL,
            "aggregate_version" int8 NOT NULL,
            "role_id" UUID NOT NULL,
            "scope_id" UUID NOT NULL,
            "created_at" timestamp NOT NULL,
            "permissions_to_add" JSONB NOT NULL,
            "permissions_to_remove" JSONB NOT NULL,
            "status" varchar NOT NULL
          );
        )

        m << %(CREATE UNIQUE INDEX roles_permissions_updates_uuid_idx ON "projections"."roles_permissions_updates"(uuid);)
        m << %(CREATE INDEX roles_permissions_updates_role_id_idx ON "projections"."roles_permissions_updates"(role_id);)

        m.each { |s| @projection_database.exec s }
      end

      # Requested — insert a new permissions update request as pending approval
      def apply(event : ::Roles::PermissionsUpdate::Events::Requested)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

        body = event.body.as(::Roles::PermissionsUpdate::Events::Requested::Body)

        # Resolve the scope_id of the role so it can be used for access control queries
        role_scope_id = @projection_database.query_one(
          %(SELECT scope_id FROM "projections"."roles" WHERE uuid = $1),
          body.role_id,
          as: UUID
        )

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."roles_permissions_updates" (
                uuid,
                aggregate_version,
                role_id,
                scope_id,
                created_at,
                permissions_to_add,
                permissions_to_remove,
                status
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          ),
            aggregate_id,
            aggregate_version,
            body.role_id,
            role_scope_id,
            created_at,
            body.permissions_to_add.to_json,
            body.permissions_to_remove.to_json,
            "pending_approval"
        end
      end

      # Completed — mark the update request as completed
      def apply(event : ::Roles::PermissionsUpdate::Events::Completed)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."roles_permissions_updates" SET status=$1, aggregate_version=$2 WHERE uuid=$3),
            "completed",
            aggregate_version,
            aggregate_id
        end
      end
    end
  end
end
