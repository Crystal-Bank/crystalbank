module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Projections
    class CreditTransfers < ES::Projection
      def prepare
        exists = @projection_database.query_one %(
          SELECT EXISTS (
            SELECT FROM pg_tables
            WHERE schemaname = 'projections' AND tablename = 'sepa_credit_transfers'
          );
        ), as: Bool

        return true if exists

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."sepa_credit_transfers" (
            "uuid"                  UUID PRIMARY KEY,
            "aggregate_version"     int8 NOT NULL,
            "scope_id"              UUID NOT NULL,
            "end_to_end_id"         varchar NOT NULL,
            "debtor_account_id"     UUID NOT NULL,
            "creditor_iban"         varchar NOT NULL,
            "creditor_name"         varchar NOT NULL,
            "creditor_bic"          varchar,
            "amount"                int8 NOT NULL,
            "currency"              varchar NOT NULL DEFAULT 'EUR',
            "execution_date"        date NOT NULL,
            "remittance_information" varchar NOT NULL,
            "status"                varchar NOT NULL,
            "ledger_transaction_id" UUID,
            "created_at"            timestamp NOT NULL,
            "updated_at"            timestamp NOT NULL
          );
        )

        m << %(CREATE INDEX sepa_credit_transfers_scope_id_idx ON "projections"."sepa_credit_transfers"(scope_id);)
        m << %(CREATE INDEX sepa_credit_transfers_status_idx ON "projections"."sepa_credit_transfers"(status);)

        m.each { |s| @projection_database.exec s }
      end

      def apply(event : Payments::Sepa::CreditTransfers::Initiation::Events::Requested)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

        body = event.body.as(Payments::Sepa::CreditTransfers::Initiation::Events::Requested::Body)

        @projection_database.exec %(
          INSERT INTO "projections"."sepa_credit_transfers" (
            uuid,
            aggregate_version,
            scope_id,
            end_to_end_id,
            debtor_account_id,
            creditor_iban,
            creditor_name,
            creditor_bic,
            amount,
            currency,
            execution_date,
            remittance_information,
            status,
            created_at,
            updated_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'EUR', $10, $11, 'pending_approval', $12, $12)
        ),
          aggregate_id,
          aggregate_version,
          body.scope_id,
          body.end_to_end_id,
          body.debtor_account_id,
          body.creditor_iban,
          body.creditor_name,
          body.creditor_bic,
          body.amount,
          body.execution_date,
          body.remittance_information,
          created_at
      end

      def apply(event : Payments::Sepa::CreditTransfers::Initiation::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        updated_at = event.header.created_at

        body = event.body.as(Payments::Sepa::CreditTransfers::Initiation::Events::Accepted::Body)

        @projection_database.exec %(
          UPDATE "projections"."sepa_credit_transfers"
          SET
            status = 'accepted',
            ledger_transaction_id = $1,
            aggregate_version = $2,
            updated_at = $3
          WHERE uuid = $4
        ),
          body.ledger_transaction_id,
          aggregate_version,
          updated_at,
          aggregate_id
      end
    end
  end
end
