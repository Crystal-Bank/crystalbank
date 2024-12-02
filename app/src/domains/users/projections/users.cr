module CrystalBank::Domains::Users
  module Projections
    class Users < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename  = 'users');), as: Bool
        return true if skip

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."users" (
            "id" SERIAL PRIMARY KEY,
            "uuid" UUID NOT NULL,
            "aggregate_version" int8 NOT NULL,
            "created_at" timestamp NOT NULL,
            "name" varchar NOT NULL,
            "email" varchar NOT NULL
          );
        )

        m << %(CREATE UNIQUE INDEX users_uuid_idx ON "projections"."users"(uuid);)

        m.each { |s| @projection_database.exec s }
      end

      # Created
      def apply(event : ::Users::Onboarding::Events::Accepted)
        # Extract attributes to local variables
        uuid = event.header.event_id
        created_at = event.header.created_at
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        # Build the account aggregate up to the version of the event
        aggregate = ::Users::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        # Extract attributes to local variables
        name = aggregate.state.name
        email = aggregate.state.email 

        # Insert the account projection into the projection database
        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."users" (
                uuid,
                aggregate_version,
                created_at,
                name,
                email
              )
              VALUES ($1, $2, $3, $4, $5)
          ),
            aggregate_id,
            aggregate_version,
            created_at,
            name,
            email
        end
      end
    end
  end
end
