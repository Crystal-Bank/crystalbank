module CrystalBank::Domains::ApiKeys
  module Projections
    class ApiKeys < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename  = 'api_keys');), as: Bool

        unless skip
          m = Array(String).new
          m << %(
            CREATE TABLE "projections"."api_keys" (
              "id" SERIAL PRIMARY KEY,
              "uuid" UUID NOT NULL,
              "aggregate_version" int8 NOT NULL,
              "scope_id" UUID NOT NULL,
              "created_at" timestamp NOT NULL,
              "name" varchar NOT NULL,
              "user_id" UUID NOT NULL,
              "encrypted_secret" varchar NOT NULL,
              "active" boolean NOT NULL default false,
              "pending_approval" boolean NOT NULL default false,
              "revoked_at" timestamp NULL
            );
          )

          m << %(CREATE UNIQUE INDEX api_keys_uuid_idx ON "projections"."api_keys"(uuid);)

          m.each { |s| @projection_database.exec s }
        end
      end

      # ApiKeys::Generation::Events::Requested
      def apply(event : ::ApiKeys::Generation::Events::Requested)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

        body = event.body.as(::ApiKeys::Generation::Events::Requested::Body)

        @projection_database.exec %(
          INSERT INTO
            "projections"."api_keys" (
              uuid,
              aggregate_version,
              scope_id,
              created_at,
              name,
              user_id,
              encrypted_secret,
              active,
              pending_approval
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ),
          aggregate_id,
          aggregate_version,
          body.scope_id,
          created_at,
          body.name,
          body.user_id,
          body.api_secret,
          false,
          true
      end

      # ApiKeys::Generation::Events::Accepted
      def apply(event : ::ApiKeys::Generation::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.exec %(
          UPDATE "projections"."api_keys"
          SET active=$1, pending_approval=$2, aggregate_version=$3
          WHERE uuid=$4
        ),
          true,
          false,
          aggregate_version,
          aggregate_id
      end

      # ApiKeys::Revocation::Events::Accepted
      def apply(event : ::ApiKeys::Revocation::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        # Build the aggregate up to the version of the event
        aggregate = ::ApiKeys::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        @projection_database.exec %(
          UPDATE "projections"."api_keys"
          SET active=$1, revoked_at=$2
          WHERE uuid=$3
        ),
          false,
          aggregate.state.revoked_at,
          aggregate_id
      end
    end
  end
end
