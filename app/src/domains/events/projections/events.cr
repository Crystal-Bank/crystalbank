module CrystalBank::Domains::Events
  module Projections
    class Events < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename = 'events');), as: Bool
        return true if skip

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."events" (
            "event_id"          UUID PRIMARY KEY,
            "aggregate_id"      UUID NOT NULL,
            "aggregate_type"    VARCHAR NOT NULL,
            "aggregate_version" INT8 NOT NULL,
            "event_handle"      VARCHAR NOT NULL,
            "scope_id"          UUID NOT NULL,
            "actor_id"          UUID,
            "created_at"        TIMESTAMP NOT NULL
          );
        )

        m << %(CREATE INDEX events_aggregate_id_idx   ON "projections"."events"(aggregate_id);)
        m << %(CREATE INDEX events_scope_id_idx       ON "projections"."events"(scope_id);)
        m << %(CREATE INDEX events_aggregate_type_idx ON "projections"."events"(aggregate_type);)
        m << %(CREATE INDEX events_event_handle_idx   ON "projections"."events"(event_handle);)
        m << %(CREATE INDEX events_created_at_idx     ON "projections"."events"(created_at);)

        m.each { |s| @projection_database.exec s }
      end

      # ---------------------------------------------------------------------------
      # Category A — events with scope_id in body (all Requested events)
      # ---------------------------------------------------------------------------

      def apply(event : ::Accounts::Opening::Events::Requested)
        body = event.body.as(::Accounts::Opening::Events::Requested::Body)
        insert_event(event, body.scope_id, "Account", "account.opening.requested")
      end

      def apply(event : ::ApiKeys::Generation::Events::Requested)
        body = event.body.as(::ApiKeys::Generation::Events::Requested::Body)
        insert_event(event, body.scope_id, "ApiKey", "api_key.generation.requested")
      end

      def apply(event : ::ApiKeys::Revocation::Events::Requested)
        body = event.body.as(::ApiKeys::Revocation::Events::Requested::Body)
        insert_event(event, body.scope_id, "ApiKey", "api_key.revocation.requested")
      end

      def apply(event : ::Approvals::Creation::Events::Requested)
        body = event.body.as(::Approvals::Creation::Events::Requested::Body)
        insert_event(event, body.scope_id, "Approval", "approval.creation.requested")
      end

      def apply(event : ::Customers::Onboarding::Events::Requested)
        body = event.body.as(::Customers::Onboarding::Events::Requested::Body)
        insert_event(event, body.scope_id, "Customer", "customer.onboarding.requested")
      end

      def apply(event : ::Ledger::Transactions::Request::Events::Requested)
        body = event.body.as(::Ledger::Transactions::Request::Events::Requested::Body)
        insert_event(event, body.scope_id, "LedgerTransaction", "ledger.transactions.request.requested")
      end

      def apply(event : ::Payments::Sepa::CreditTransfers::Initiation::Events::Requested)
        body = event.body.as(::Payments::Sepa::CreditTransfers::Initiation::Events::Requested::Body)
        insert_event(event, body.scope_id, "Payments.Sepa.CreditTransfer", "payments.sepa.credit_transfers.initiation.requested")
      end

      def apply(event : ::Roles::Creation::Events::Requested)
        body = event.body.as(::Roles::Creation::Events::Requested::Body)
        insert_event(event, body.scope_id, "Role", "role.creation.requested")
      end

      def apply(event : ::Scopes::Creation::Events::Requested)
        body = event.body.as(::Scopes::Creation::Events::Requested::Body)
        insert_event(event, body.scope_id, "Scope", "scope.creation.requested")
      end

      def apply(event : ::Users::Onboarding::Events::Requested)
        body = event.body.as(::Users::Onboarding::Events::Requested::Body)
        insert_event(event, body.scope_id, "User", "user.onboarding.requested")
      end

      def apply(event : ::Users::AssignRoles::Events::Requested)
        body = event.body.as(::Users::AssignRoles::Events::Requested::Body)
        insert_event(event, body.scope_id, "User", "user.assign_roles.requested")
      end

      # ---------------------------------------------------------------------------
      # Category B — events without scope_id in body; derived via self-lookup
      # ---------------------------------------------------------------------------

      def apply(event : ::Accounts::Opening::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id), "Account", "account.opening.accepted")
      end

      def apply(event : ::ApiKeys::Generation::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id), "ApiKey", "api_key.generation.accepted")
      end

      def apply(event : ::ApiKeys::Revocation::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id), "ApiKey", "api_key.revocation.accepted")
      end

      def apply(event : ::Approvals::Collection::Events::Collected)
        insert_event(event, scope_id_for(event.header.aggregate_id), "Approval", "approval.collection.collected")
      end

      def apply(event : ::Approvals::Collection::Events::Completed)
        insert_event(event, scope_id_for(event.header.aggregate_id), "Approval", "approval.collection.completed")
      end

      def apply(event : ::Approvals::Rejection::Events::Rejected)
        insert_event(event, scope_id_for(event.header.aggregate_id), "Approval", "approval.rejection.rejected")
      end

      def apply(event : ::Customers::Onboarding::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id), "Customer", "customer.onboarding.accepted")
      end

      def apply(event : ::Ledger::Transactions::Request::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id), "LedgerTransaction", "ledger.transactions.request.accepted")
      end

      def apply(event : ::Payments::Sepa::CreditTransfers::Initiation::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id), "Payments.Sepa.CreditTransfer", "payments.sepa.credit_transfers.initiation.accepted")
      end

      def apply(event : ::Roles::Creation::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id), "Role", "role.creation.accepted")
      end

      def apply(event : ::Scopes::Creation::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id), "Scope", "scope.creation.accepted")
      end

      def apply(event : ::Users::Onboarding::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id), "User", "user.onboarding.accepted")
      end

      def apply(event : ::Users::AssignRoles::Events::Accepted)
        insert_event(event, scope_id_for(event.header.aggregate_id), "User", "user.assign_roles.accepted")
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

      private def insert_event(event : ES::Event, scope_id : UUID, aggregate_type : String, event_handle : String)
        @projection_database.transaction do |tx|
          tx.connection.exec %(
            INSERT INTO "projections"."events" (
              event_id,
              aggregate_id,
              aggregate_type,
              aggregate_version,
              event_handle,
              scope_id,
              actor_id,
              created_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
          ),
            event.header.event_id,
            event.header.aggregate_id,
            aggregate_type,
            event.header.aggregate_version,
            event_handle,
            scope_id,
            event.header.actor_id,
            event.header.created_at
        end
      end
    end
  end
end
