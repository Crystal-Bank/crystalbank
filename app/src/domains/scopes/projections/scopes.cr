module CrystalBank::Domains::Scopes
  module Projections
    class Scopes < ES::Projection
      include ES::ProjectionDSL

      define_projection "projections.scopes", init: true do
        column :id, Int32, serial: true, primary_key: true
        column :uuid, UUID, null: false
        column :aggregate_version, Int64, null: false
        column :scope_id, UUID, null: false
        column :created_at, Time, null: false
        column :name, String, null: false
        column :parent_scope_id, UUID, null: true
        column :status, String, null: false

        index [:uuid], unique: true, name: "scopes_uuid_idx"
      end

      apply(::Scopes::Creation::Events::Requested) do
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

      apply(::Scopes::NameChange::Events::Accepted) do
        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."scopes" SET name=$1, aggregate_version=$2 WHERE uuid=$3),
            body.name,
            aggregate_version,
            aggregate_id
        end
      end

      apply(::Scopes::Creation::Events::Accepted) do
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
