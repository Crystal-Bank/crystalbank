module CrystalBank::Domains::Users
  module Projections
    class Users < ES::Projection
      include ES::ProjectionDSL

      define_projection "projections.users", init: true do
        column :id, Int32, serial: true, primary_key: true
        column :uuid, UUID, null: false
        column :aggregate_version, int8, null: false
        column :scope_id, UUID, null: false
        column :role_ids, JSON, null: false
        column :created_at, Time, null: false
        column :name, String, null: false
        column :email, String, null: false
        column :status, String, null: false

        index [:uuid], unique: true, name: "users_uuid_idx"
      end

      apply(::Users::Onboarding::Events::Requested) do
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

        body = event.body.as(::Users::Onboarding::Events::Requested::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."users" (
                uuid,
                aggregate_version,
                scope_id,
                role_ids,
                created_at,
                name,
                email,
                status
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          ),
            aggregate_id,
            aggregate_version,
            body.scope_id,
            "[]",
            created_at,
            body.name,
            body.email,
            "pending_approval"
        end
      end

      apply(::Users::Onboarding::Events::Accepted) do
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."users" SET status=$1, aggregate_version=$2 WHERE uuid=$3),
            "active",
            aggregate_version,
            aggregate_id
        end
      end

      apply(::Users::RemoveRoles::Events::Accepted) do
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        aggregate = ::Users::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        role_ids = aggregate.state.role_ids

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE
              "projections"."users"
            SET
              role_ids=$1,
              aggregate_version=$2
            WHERE
              uuid=$3;
          ),
            role_ids.to_json,
            aggregate_version,
            aggregate_id
        end
      end

      apply(::Users::AssignRoles::Events::Accepted) do
        uuid = event.header.event_id
        created_at = event.header.created_at
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        aggregate = ::Users::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        role_ids = aggregate.state.role_ids

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE
              "projections"."users"
            SET
              role_ids=$1,
              aggregate_version=$2
            WHERE
              uuid=$3;
          ),
            role_ids.to_json,
            aggregate_version,
            aggregate_id
        end
      end
    end
  end
end
