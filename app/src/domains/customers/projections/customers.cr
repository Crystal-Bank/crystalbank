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
            "created_at" timestamp NOT NULL,
            "name" varchar NOT NULL,
            "type" varchar NOT NULL
          );
        )

        m << %(CREATE UNIQUE INDEX customers_uuid_idx ON "projections"."customers"(uuid);)

        m.each { |s| @projection_database.exec s }
      end

      # Accepted
      def apply(event : ::Customers::Onboarding::Events::Accepted)
        # Extract attributes to local variables
        uuid = event.header.event_id
        created_at = event.header.created_at
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        # Build the customer aggregate up to the version of the event
        aggregate = ::Customers::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        # Extract attributes to local variables
        name = aggregate.state.name
        type = aggregate.state.type.to_s.downcase

        # Insert the customer projection into the projection database
        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."customers" (
                uuid,
                aggregate_version,
                created_at,
                type,
                name
              )
              VALUES ($1, $2, $3, $4, $5)
          ),
            aggregate_id,
            aggregate_version,
            created_at,
            type.to_s,
            name
        end
      end
    end
  end
end
