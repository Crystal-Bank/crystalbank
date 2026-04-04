module CrystalBank::Domains::Customers
  module Projections
    class Customers < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename  = 'customers');), as: Bool
        return true if skip

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."customers" (
            "id" SERIAL PRIMARY KEY,
            "uuid" UUID NOT NULL,
            "aggregate_version" int8 NOT NULL,
            "scope_id" UUID NOT NULL,
            "created_at" timestamp NOT NULL,
            "name" varchar NOT NULL,
            "type" varchar NOT NULL,
            "status" varchar NOT NULL
          );
        )

        m << %(CREATE UNIQUE INDEX customers_uuid_idx ON "projections"."customers"(uuid);)

        m.each { |s| @projection_database.exec s }
      end

      # Pending — insert customer as pending when onboarding is requested
      def apply(event : ::Customers::Onboarding::Events::Requested)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

        aggregate = ::Customers::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        name = aggregate.state.name
        scope_id = aggregate.state.scope_id
        type = aggregate.state.type.to_s.downcase

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
              VALUES ($1, $2, $3, $4, $5, $6, 'pending')
          ),
            aggregate_id,
            aggregate_version,
            scope_id,
            created_at,
            type.to_s,
            name
        end
      end

      # Accepted — mark customer as active once approval is complete
      def apply(event : ::Customers::Onboarding::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE "projections"."customers"
            SET status = 'active', aggregate_version = $1
            WHERE uuid = $2
          ),
            aggregate_version,
            aggregate_id
        end
      end
    end
  end
end
