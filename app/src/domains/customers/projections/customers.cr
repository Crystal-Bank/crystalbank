module CrystalBank::Domains::Customers
  module Projections
    class Customers < ES::Projection
      include ES::ProjectionDSL

      define_projection "projections.customers", init: true do
        column :id, Int32, serial: true, primary_key: true
        column :uuid, UUID, null: false
        column :aggregate_version, Int64, null: false
        column :scope_id, UUID, null: false
        column :created_at, Time, null: false
        column :name, String, null: false
        column :type, String, null: false
        column :status, String, null: false

        index [:uuid], unique: true, name: "customers_uuid_idx"
      end

      apply(::Customers::Onboarding::Events::Requested) do
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

        body = event.body.as(::Customers::Onboarding::Events::Requested::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."customers" (
                uuid,
                aggregate_version,
                scope_id,
                created_at,
                type,
                name,
                status
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7)
          ),
            aggregate_id,
            aggregate_version,
            body.scope_id,
            created_at,
            body.type.to_s.downcase,
            body.name,
            "pending_approval"
        end
      end

      apply(::Customers::Onboarding::Events::Accepted) do
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."customers" SET status=$1, aggregate_version=$2 WHERE uuid=$3),
            "active",
            aggregate_version,
            aggregate_id
        end
      end
    end
  end
end
