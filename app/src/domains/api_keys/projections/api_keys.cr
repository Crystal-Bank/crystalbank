module CrystalBank::Domains::ApiKeys
  module Projections
    class ApiKeys < ES::Projection
      include ES::ProjectionDSL

      define_projection "projections.api_keys", init: true do
        column :id, Int32, serial: true, primary_key: true
        column :uuid, UUID, null: false
        column :aggregate_version, int8, null: false
        column :scope_id, UUID, null: false
        column :created_at, Time, null: false
        column :name, String, null: false
        column :user_id, UUID, null: false
        column :encrypted_secret, String, null: false
        column :status, String, null: false
        column :revoked_at, Time, null: true

        index [:uuid], unique: true, name: "api_keys_uuid_idx"
      end

      apply(::ApiKeys::Generation::Events::Requested) do
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

        body = event.body.as(::ApiKeys::Generation::Events::Requested::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."api_keys" (
                uuid,
                aggregate_version,
                scope_id,
                created_at,
                name,
                user_id,
                encrypted_secret,
                status
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          ),
            aggregate_id,
            aggregate_version,
            body.scope_id,
            created_at,
            body.name,
            body.user_id,
            body.api_secret,
            "pending_approval"
        end
      end

      apply(::ApiKeys::Generation::Events::Accepted) do
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."api_keys" SET status=$1, aggregate_version=$2 WHERE uuid=$3),
            "active",
            aggregate_version,
            aggregate_id
        end
      end

      apply(::ApiKeys::Revocation::Events::Accepted) do
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        aggregate = ::ApiKeys::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        revoked_at = aggregate.state.revoked_at

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."api_keys" SET status=$1, revoked_at=$2, aggregate_version=$3 WHERE uuid=$4),
            "revoked",
            revoked_at,
            aggregate_version,
            aggregate_id
        end
      end
    end
  end
end
