module CrystalBank::Domains::Events
  module Projections
    class Events < ES::Projection
      include ES::ProjectionDSL

      define_projection "projections.events", init: true do
        column :event_id, UUID, primary_key: true
        column :aggregate_id, UUID, null: false
        column :aggregate_version, Int64, null: false
        column :scope_id, UUID, null: false
        column :header, JSON::Any, null: false
        column :body, JSON::Any, null: true

        index [:aggregate_id], name: "events_aggregate_id_idx"
        index [:scope_id], name: "events_scope_id_idx"
      end

      # ---------------------------------------------------------------------------
      # Category A — events with scope_id in body (all Requested events)
      # ---------------------------------------------------------------------------

      apply(::Accounts::Opening::Events::Requested) do
        insert_event(event, event.body.as(::Accounts::Opening::Events::Requested::Body).scope_id)
      end

      apply(::ApiKeys::Generation::Events::Requested) do
        insert_event(event, event.body.as(::ApiKeys::Generation::Events::Requested::Body).scope_id)
      end

      apply(::ApiKeys::Revocation::Events::Requested) do
        insert_event(event, event.body.as(::ApiKeys::Revocation::Events::Requested::Body).scope_id)
      end

      apply(::Approvals::Creation::Events::Requested) do
        insert_event(event, event.body.as(::Approvals::Creation::Events::Requested::Body).scope_id)
      end

      apply(::Customers::Onboarding::Events::Requested) do
        insert_event(event, event.body.as(::Customers::Onboarding::Events::Requested::Body).scope_id)
      end

      apply(::Ledger::Transactions::Request::Events::Requested) do
        insert_event(event, event.body.as(::Ledger::Transactions::Request::Events::Requested::Body).scope_id)
      end

      apply(::Payments::Sepa::CreditTransfers::Initiation::Events::Requested) do
        insert_event(event, event.body.as(::Payments::Sepa::CreditTransfers::Initiation::Events::Requested::Body).scope_id)
      end

      apply(::Roles::Creation::Events::Requested) do
        insert_event(event, event.body.as(::Roles::Creation::Events::Requested::Body).scope_id)
      end

      apply(::Scopes::Creation::Events::Requested) do
        insert_event(event, event.body.as(::Scopes::Creation::Events::Requested::Body).scope_id)
      end

      apply(::Users::Onboarding::Events::Requested) do
        insert_event(event, event.body.as(::Users::Onboarding::Events::Requested::Body).scope_id)
      end

      apply(::Users::AssignRoles::Events::Requested) do
        insert_event(event, event.body.as(::Users::AssignRoles::Events::Requested::Body).scope_id)
      end

      # ---------------------------------------------------------------------------
      # Category B — events without scope_id in body; derived via self-lookup
      # ---------------------------------------------------------------------------

      apply(::Accounts::Opening::Events::Accepted) do
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      apply(::ApiKeys::Generation::Events::Accepted) do
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      apply(::ApiKeys::Revocation::Events::Accepted) do
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      apply(::Approvals::Collection::Events::Collected) do
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      apply(::Approvals::Collection::Events::Completed) do
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      apply(::Approvals::Rejection::Events::Rejected) do
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      apply(::Customers::Onboarding::Events::Accepted) do
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      apply(::Ledger::Transactions::Request::Events::Accepted) do
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      apply(::Payments::Sepa::CreditTransfers::Initiation::Events::Accepted) do
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      apply(::Roles::Creation::Events::Accepted) do
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      apply(::Scopes::Creation::Events::Accepted) do
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      apply(::Users::Onboarding::Events::Accepted) do
        insert_event(event, scope_id_for(event.header.aggregate_id))
      end

      apply(::Users::AssignRoles::Events::Accepted) do
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
