module CrystalBank::Domains::Ledger::Transactions
  module Projections
    class Postings < ES::Projection
      include ES::ProjectionDSL

      define_projection "projections.postings", init: true do
        column :id, UUID, primary_key: true
        column :transaction_id, UUID, null: false
        column :aggregate_version, Int64, null: false
        column :scope_id, UUID, null: false
        column :created_at, Time, null: false
        column :account_id, UUID, null: false
        column :direction, String, null: false
        column :amount, Int64, null: false
        column :entry_type, String, null: false
        column :currency, String, null: false
        column :posting_date, Time, null: true
        column :value_date, Time, null: true
        column :remittance_information, String, null: false
        column :payment_type, String, null: true
        column :external_ref, String, null: true
        column :channel, String, null: true
        column :status, String, null: false

        index [:transaction_id], name: "postings_transaction_id_idx"
      end

      apply(::Ledger::Transactions::Request::Events::Accepted) do
        aggregate = ::Ledger::Transactions::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        channel = aggregate.state.channel
        currency = aggregate.state.currency
        entries = aggregate.state.entries
        external_ref = aggregate.state.external_ref
        payment_type = aggregate.state.payment_type
        posting_date = aggregate.state.posting_date
        remittance_information = aggregate.state.remittance_information.to_s
        scope_id = aggregate.state.scope_id
        value_date = aggregate.state.value_date

        raise "Invalid ledger transaction state: missing entries" if entries.nil?
        raise "Invalid ledger transaction state: missing currency" if currency.nil?

        @projection_database.transaction do |tx|
          cnn = tx.connection
          entries.each do |entry|
            cnn.exec %(
              INSERT INTO
                "projections"."postings" (
                  id,
                  transaction_id,
                  aggregate_version,
                  scope_id,
                  created_at,
                  account_id,
                  direction,
                  amount,
                  entry_type,
                  currency,
                  posting_date,
                  value_date,
                  remittance_information,
                  payment_type,
                  external_ref,
                  channel,
                  status
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
            ),
              entry.id,
              aggregate_id,
              aggregate_version,
              scope_id,
              created_at,
              entry.account_id,
              entry.direction,
              entry.amount,
              entry.entry_type,
              currency.to_s,
              posting_date,
              value_date,
              remittance_information,
              payment_type,
              external_ref,
              channel,
              "active"
          end
        end
      end
    end
  end
end
