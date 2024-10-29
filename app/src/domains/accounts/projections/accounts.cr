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
            "created_at" timestamp NOT NULL,
            "currencies" varchar NOT NULL,
            "type" varchar NOT NULL
          );
        )

        m << %(CREATE UNIQUE INDEX accounts_uuid_idx ON "projections"."accounts"(uuid);)

        m.each { |s| @projection_database.exec s }
      end

      # Created
      def apply(event : ::Accounts::Opening::Events::Accepted)
        # Extract attributes to local variables
        uuid = event.header.event_id
        created_at = event.header.created_at
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        # Build the account aggregate up to the version of the event
        aggregate = ::Accounts::Aggregate.new(aggregate_id, event_store: @event_store, event_handlers: @event_handlers)
        aggregate.hydrate(version: aggregate_version)

        # Extract attributes to local variables
        currencies = ["eur", "usd"] # aggregate.state.currencies
        type = "checking" # aggregagte.state.type

        # Insert the account projection into the projection database
        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO 
              "projections"."accounts" (
                uuid,
                aggregate_version,
                created_at,
                type,
                currencies
              )
              VALUES ($1, $2, $3, $4, $5)
          ),
            aggregate_id,
            aggregate_version,
            created_at,
            type,
            currencies
        end
      end
    end
  end
end
