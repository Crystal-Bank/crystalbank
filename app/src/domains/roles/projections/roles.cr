module CrystalBank::Domains::Roles
  module Projections
    class Roles < ES::Projection
      include ES::ProjectionDSL

      define_projection "projections.roles", init: true do
        column :id, Int32, serial: true, primary_key: true
        column :uuid, UUID, null: false
        column :aggregate_version, int8, null: false
        column :scope_id, UUID, null: false
        column :created_at, Time, null: false
        column :name, String, null: false
        column :permissions, JSON, null: false
        column :scopes, JSON, null: false
        column :status, String, null: false

        index [:uuid], unique: true, name: "roles_uuid_idx"
      end

      apply(::Roles::Creation::Events::Requested) do
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

      apply(::Roles::Creation::Events::Accepted) do
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

      apply(::Roles::PermissionsUpdate::Events::Accepted) do
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        body = event.body.as(::Roles::PermissionsUpdate::Events::Accepted::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."roles" SET permissions=$1, aggregate_version=$2 WHERE uuid=$3),
            body.permissions.to_json,
            aggregate_version,
            aggregate_id
        end
      end
    end
  end
end
