module CrystalBank::Domains::Payments::Sepa::CreditTransfers
  module Projections
    class CreditTransfers < ES::Projection
      include ES::ProjectionDSL

      define_projection "projections.sepa_credit_transfers", init: true do
        column :uuid, UUID, primary_key: true
        column :aggregate_version, int8, null: false
        column :scope_id, UUID, null: false
        column :end_to_end_id, String, null: false
        column :debtor_account_id, UUID, null: false
        column :creditor_iban, String, null: false
        column :creditor_name, String, null: false
        column :creditor_bic, String, null: true
        column :amount, int8, null: false
        column :currency, String, null: false, default: "EUR"
        column :execution_date, Time, null: false
        column :remittance_information, String, null: false
        column :status, String, null: false
        column :ledger_transaction_id, UUID, null: true
        column :created_at, Time, null: false
        column :updated_at, Time, null: false

        index [:scope_id], name: "sepa_credit_transfers_scope_id_idx"
        index [:status], name: "sepa_credit_transfers_status_idx"
      end

      apply(Payments::Sepa::CreditTransfers::Initiation::Events::Requested) do
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

      apply(Payments::Sepa::CreditTransfers::Initiation::Events::Accepted) do
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
