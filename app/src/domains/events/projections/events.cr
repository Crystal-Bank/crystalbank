module CrystalBank::Domains::Events
  module Projections
    class Events < ES::Projection
      def prepare
        table_exists = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename = 'events');), as: Bool

        if table_exists
          # Migrate: drop and recreate if the old schema with redundant columns is present
          old_schema = @projection_database.query_one %(SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_schema = 'projections' AND table_name = 'events' AND column_name = 'aggregate_type');), as: Bool
          if old_schema
            @projection_database.exec %(DROP TABLE "projections"."events")
          else
            return true
          end
        end

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."events" (
            "event_id"          UUID PRIMARY KEY,
            "aggregate_id"      UUID NOT NULL,
            "aggregate_version" INT8 NOT NULL,
            "scope_id"          UUID NOT NULL,
            "header"            JSONB NOT NULL,
            "body"              JSONB
          );
        )

        m << %(CREATE INDEX events_aggregate_id_idx   ON "projections"."events"(aggregate_id);)
        m << %(CREATE INDEX events_scope_id_idx       ON "projections"."events"(scope_id);)
        m << %(CREATE INDEX events_aggregate_type_idx ON "projections"."events"((header->>'aggregate_type'));)
        m << %(CREATE INDEX events_event_handle_idx   ON "projections"."events"((header->>'event_handle'));)
        m << %(CREATE INDEX events_created_at_idx     ON "projections"."events"((header->>'created_at'));)

        m.each { |s| @projection_database.exec s }
      end

      # ---------------------------------------------------------------------------
      # Category A — events with scope_id in body (all Requested events)
      # ---------------------------------------------------------------------------

      def apply(event : ::Accounts::Opening::Events::Requested)
        insert_event(event, event.body.as(::Accounts::Opening::Events::Requested::Body).scope_id)
      end

      def apply(event : ::ApiKeys::Generation::Events::Requested)
        insert_event(event, event.body.as(::ApiKeys::Generation::Events::Requested::Body).scope_id)
      end

      def apply(event : ::ApiKeys::Revocation::Events::Requested)
        insert_event(event, event.body.as(::ApiKeys::Revocation::Events::Requested::Body).scope_id)
      end

      def apply(event : ::Approvals::Creation::Events::Requested)
        insert_event(event, event.body.as(::Approvals::Creation::Events::Requested::Body).scope_id)
      end

      def apply(event : ::Customers::Onboarding::Events::Requested)
        insert_event(event, event.body.as(::Customers::Onboarding::Events::Requested::Body).scope_id)
      end

      def apply(event : ::Ledger::Transactions::Request::Events::Requested)
        insert_event(event, event.body.as(::Ledger::Transactions::Request::Events::Requested::Body).scope_id)
      end

      def apply(event : ::Payments::Sepa::CreditTransfers::Initiation::Events::Requested)
        insert_event(event, event.body.as(::Payments::Sepa::CreditTransfers::Initiation::Events::Requested::Body).scope_id)
      end

      def apply(event : ::Roles::Creation::Events::Requested)
        insert_event(event, event.body.as(::Roles::Creation::Events::Requested::Body).scope_id)
      end

      def apply(event : ::Scopes::Creation::Events::Requested)
        insert_event(event, event.body.as(::Scopes::Creation::Events::Requested::Body).scope_id)
      end

      def apply(event : ::Users::Onboarding::Events::Requested)
        insert_event(event, event.body.as(::Users::Onboarding::Events::Requested::Body).scope_id)
      end

      def apply(event : ::Users::AssignRoles::Events::Requested)
        insert_event(event, event.body.as(::Users::AssignRoles::Events::Requested::Body).scope_id)
      end

      # ---------------------------------------------------------------------------
      # Category B — events without scope_id in body; derived via self-lookup
      # ---------------------------------------------------------------------------

      def apply(event : ::Accounts::Opening::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      def apply(event : ::ApiKeys::Generation::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      def apply(event : ::ApiKeys::Revocation::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      def apply(event : ::Approvals::Collection::Events::Collected)
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      def apply(event : ::Approvals::Collection::Events::Completed)
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      def apply(event : ::Approvals::Rejection::Events::Rejected)
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      def apply(event : ::Customers::Onboarding::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      def apply(event : ::Ledger::Transactions::Request::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      def apply(event : ::Payments::Sepa::CreditTransfers::Initiation::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      def apply(event : ::Roles::Creation::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      def apply(event : ::Scopes::Creation::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      def apply(event : ::Users::Onboarding::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      def apply(event : ::Users::AssignRoles::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      # ---------------------------------------------------------------------------
      # Private helpers
      # ---------------------------------------------------------------------------

      private def scope_id_for(aggregate_id : UUID) : UUID
        @projection_database.query_one(
          %(SELECT "scope_id" FROM "projections"."events" WHERE "aggregate_id" = $1 ORDER BY "aggregate_version" ASC LIMIT 1),
          aggregate_id,
          as: UUID
        )
      end

      private def insert_event(event : ES::Event, scope_id : UUID)
        @projection_database.transaction do |tx|
          tx.connection.exec %(
            INSERT INTO "projections"."events" (
              event_id,
              aggregate_id,
              aggregate_version,
              scope_id,
              header,
              body
            ) VALUES ($1, $2, $3, $4, $5, $6)
          ),
            event.header.event_id,
            event.header.aggregate_id,
            event.header.aggregate_version,
            scope_id,
            event.header.to_json,
            event.body.try(&.to_json)
        end
      end
    end
  end
end
