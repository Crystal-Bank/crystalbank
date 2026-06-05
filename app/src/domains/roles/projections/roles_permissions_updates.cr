module CrystalBank::Domains::Roles
  module Projections
    class RolesPermissionsUpdates < ES::Projection
      include ES::ProjectionDSL

      define_projection "projections.roles_permissions_updates", init: true do
        column :id, Int32, serial: true, primary_key: true
        column :uuid, UUID, null: false
        column :aggregate_version, Int64, null: false
        column :role_id, UUID, null: false
        column :scope_id, UUID, null: false
        column :created_at, Time, null: false
        column :permissions, JSON::Any, null: false
        column :status, String, null: false

        index [:uuid], unique: true, name: "roles_permissions_updates_uuid_idx"
        index [:role_id], name: "roles_permissions_updates_role_id_idx"
      end

      apply(::Roles::PermissionsUpdate::Events::Requested) do
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
                permissions,
                status
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7)
          ),
            aggregate_id,
            aggregate_version,
            body.role_id,
            role_scope_id,
            created_at,
            body.permissions.to_json,
            "pending_approval"
        end
      end

      apply(::Roles::PermissionsUpdate::Events::Completed) do
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
