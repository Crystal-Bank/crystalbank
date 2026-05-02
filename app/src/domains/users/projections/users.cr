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
            "scope_id" UUID NOT NULL,
            "role_ids" JSONB NOT NULL,
            "created_at" timestamp NOT NULL,
            "name" varchar NOT NULL,
            "email" varchar NOT NULL,
            "status" varchar NOT NULL
          );
        )

        m << %(CREATE UNIQUE INDEX users_uuid_idx ON "projections"."users"(uuid);)

        m.each { |s| @projection_database.exec s }
      end

      # Requested
      def apply(event : ::Users::Onboarding::Events::Requested)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

        body = event.body.as(::Users::Onboarding::Events::Requested::Body)

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."users" (
                uuid,
                aggregate_version,
                scope_id,
                role_ids,
                created_at,
                name,
                email,
                status
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          ),
            aggregate_id,
            aggregate_version,
            body.scope_id,
            "[]",
            created_at,
            body.name,
            body.email,
            "pending_approval"
        end
      end

      # Accepted
      def apply(event : ::Users::Onboarding::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(UPDATE "projections"."users" SET status=$1, aggregate_version=$2 WHERE uuid=$3),
            "active",
            aggregate_version,
            aggregate_id
        end
      end

      # Remove Roles Accepted
      def apply(event : ::Users::RemoveRoles::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        # Build the user aggregate up to the version of the event
        aggregate = ::Users::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        role_ids = aggregate.state.role_ids

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE
              "projections"."users"
            SET
              role_ids=$1,
              aggregate_version=$2
            WHERE
              uuid=$3;
          ),
            role_ids.to_json,
            aggregate_version,
            aggregate_id
        end
      end

      # Assign Roles Accepted
      def apply(event : ::Users::AssignRoles::Events::Accepted)
        # Extract attributes to local variables
        uuid = event.header.event_id
        created_at = event.header.created_at
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        # Build the account aggregate up to the version of the event
        aggregate = ::Users::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        # Extract attributes to local variables
        role_ids = aggregate.state.role_ids

        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            UPDATE
              "projections"."users"
            SET
              role_ids=$1,
              aggregate_version=$2
            WHERE
              uuid=$3;
          ),
            role_ids.to_json,
            aggregate_version,
            aggregate_id
        end
      end
    end
  end
end
