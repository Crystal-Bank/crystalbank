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

      # Requested
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

      # Accepted
      def apply(event : ::Accounts::Opening::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."accounts" SET status=$1, aggregate_version=$2 WHERE uuid=$3),
            "active",
            aggregate_version,
            aggregate_id
        end
      end

      # Closure requested — account enters pending closure state
      def apply(event : ::Accounts::Closure::Events::Requested)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."accounts" SET status=$1, aggregate_version=$2 WHERE uuid=$3),
            "closure_pending",
            aggregate_version,
            aggregate_id
        end
      end

      # Closure accepted — account is now closed
      def apply(event : ::Accounts::Closure::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

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
