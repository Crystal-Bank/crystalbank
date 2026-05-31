module CrystalBank::Domains::VirtualAccounts
  module Projections
    class VirtualAccounts < ES::Projection
      include ES::ProjectionDSL

      define_projection "projections.virtual_accounts", init: true do
        column :id, Int32, serial: true, primary_key: true
        column :uuid, UUID, null: false
        column :aggregate_version, int8, null: false
        column :parent_account_id, UUID, null: false
        column :scope_id, UUID, null: false
        column :created_at, Time, null: false
        column :name, String, null: false
        column :currencies, JSON, null: false
        column :customer_ids, JSON, null: false
        column :status, String, null: false

        index [:uuid], unique: true, name: "virtual_accounts_uuid_idx"
        index [:parent_account_id], name: "virtual_accounts_parent_idx"
      end

      apply(::VirtualAccounts::Opening::Events::Requested) do
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

        body = event.body.as(::VirtualAccounts::Opening::Events::Requested::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."virtual_accounts" (
                uuid,
                aggregate_version,
                parent_account_id,
                scope_id,
                created_at,
                name,
                currencies,
                customer_ids,
                status
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
          ),
            aggregate_id,
            aggregate_version,
            body.parent_account_id,
            body.scope_id,
            created_at,
            body.name,
            body.currencies.to_json,
            body.customer_ids.to_json,
            "pending_activation"
        end
      end

      apply(::VirtualAccounts::Opening::Events::Accepted) do
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."virtual_accounts" SET status=$1, aggregate_version=$2 WHERE uuid=$3),
            "active",
            aggregate_version,
            aggregate_id
        end
      end
    end
  end
end
