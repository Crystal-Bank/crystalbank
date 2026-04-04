module CrystalBank::Domains::Accounts
  module Projections
    class Accounts < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename  = 'accounts');), as: Bool

        return true if skip

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."accounts" (
            "id" SERIAL PRIMARY KEY,
            "uuid" UUID NOT NULL,
            "aggregate_version" int8 NOT NULL,
            "scope_id" UUID NOT NULL,
            "created_at" timestamp NOT NULL,
            "name" varchar NOT NULL,
            "currencies" jsonb NOT NULL,
            "customer_ids" jsonb NOT NULL,
            "type" varchar NOT NULL,
            "status" varchar NOT NULL
          );
        )

        m << %(CREATE UNIQUE INDEX accounts_uuid_idx ON "projections"."accounts"(uuid);)

        m.each { |s| @projection_database.exec s }
      end

      # Pending - insert account with pending status when opening is requested
      def apply(event : ::Accounts::Opening::Events::Requested)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

        body = event.body.as(::Accounts::Opening::Events::Requested::Body)

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
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'pending')
          ),
            aggregate_id,
            aggregate_version,
            body.scope_id,
            created_at,
            body.name,
            body.type.to_s.downcase,
            body.currencies.to_json,
            body.customer_ids.to_json
        end
      end

      # Active - update status to active when opening is accepted
      def apply(event : ::Accounts::Opening::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE "projections"."accounts"
            SET
              "aggregate_version" = $1,
              "status" = 'active'
            WHERE "uuid" = $2
          ),
            aggregate_version,
            aggregate_id
        end
      end
    end
  end
end
