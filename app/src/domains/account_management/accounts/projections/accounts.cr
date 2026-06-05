module CrystalBank::Domains::Accounts
  module Projections
    class Accounts < ES::Projection
      include ES::ProjectionDSL

      define_projection "projections.accounts", init: true do
        column :id, Int32, serial: true, primary_key: true
        column :uuid, UUID, null: false
        column :aggregate_version, Int64, null: false
        column :scope_id, UUID, null: false
        column :created_at, Time, null: false
        column :name, String, null: false
        column :currencies, JSON::Any, null: false
        column :customer_ids, JSON::Any, null: false
        column :type, String, null: false
        column :status, String, null: false

        index [:uuid], unique: true, name: "accounts_uuid_idx"
      end

      apply(::Accounts::Opening::Events::Requested) do
        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."accounts" (
                uuid,
                aggregate_version,
                scope_id,
                created_at,
                name,
                type,
                currencies,
                customer_ids,
                status
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
          ),
            aggregate_id,
            aggregate_version,
            body.scope_id,
            created_at,
            body.name,
            body.type.to_s.downcase,
            body.currencies.to_json,
            body.customer_ids.to_json,
            "pending_approval"
        end
      end

      apply(::Accounts::Opening::Events::Accepted) do
        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."accounts" SET status=$1, aggregate_version=$2 WHERE uuid=$3),
            "active",
            aggregate_version,
            aggregate_id
        end
      end

      apply(::Accounts::Closure::Events::Requested) do
        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."accounts" SET status=$1, aggregate_version=$2 WHERE uuid=$3),
            "closure_pending",
            aggregate_version,
            aggregate_id
        end
      end

      apply(::Accounts::Closure::Events::Accepted) do
        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."accounts" SET status=$1, aggregate_version=$2 WHERE uuid=$3),
            "closed",
            aggregate_version,
            aggregate_id
        end
      end
    end
  end
end
