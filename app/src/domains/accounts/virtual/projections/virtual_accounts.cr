module CrystalBank::Domains::Accounts
  module Virtual
    module Projections
      class VirtualAccounts < ES::Projection
        def prepare
          skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename = 'virtual_accounts');), as: Bool

          return true if skip

          m = Array(String).new
          m << %(
            CREATE TABLE "projections"."virtual_accounts" (
              "id" SERIAL PRIMARY KEY,
              "uuid" UUID NOT NULL,
              "aggregate_version" int8 NOT NULL,
              "parent_account_id" UUID NOT NULL,
              "scope_id" UUID NOT NULL,
              "created_at" timestamp NOT NULL,
              "name" varchar NOT NULL,
              "currencies" jsonb NOT NULL,
              "customer_ids" jsonb NOT NULL,
              "status" varchar NOT NULL
            );
          )

          m << %(CREATE UNIQUE INDEX virtual_accounts_uuid_idx ON "projections"."virtual_accounts"(uuid);)
          m << %(CREATE INDEX virtual_accounts_parent_idx ON "projections"."virtual_accounts"(parent_account_id);)

          m.each { |s| @projection_database.exec s }
        end

        # Requested — insert row as pending_activation
        def apply(event : ::Accounts::Virtual::Opening::Events::Requested)
          aggregate_id = event.header.aggregate_id
          aggregate_version = event.header.aggregate_version
          created_at = event.header.created_at

          body = event.body.as(::Accounts::Virtual::Opening::Events::Requested::Body)

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

        # Accepted — activate
        def apply(event : ::Accounts::Virtual::Opening::Events::Accepted)
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
end
