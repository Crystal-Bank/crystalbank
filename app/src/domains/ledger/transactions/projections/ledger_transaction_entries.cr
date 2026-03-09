module CrystalBank::Domains::Ledger::Transactions
  module Projections
    class LedgerTransactionEntries < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename = 'ledger_transaction_entries');), as: Bool
        return true if skip

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."ledger_transaction_entries" (
            "id" SERIAL PRIMARY KEY,
            "transaction_id" UUID NOT NULL,
            "aggregate_version" int8 NOT NULL,
            "created_at" timestamp NOT NULL,
            "account_id" UUID NOT NULL,
            "direction" varchar NOT NULL,
            "amount" int8 NOT NULL,
            "entry_type" varchar NOT NULL,
            "currency" varchar NOT NULL,
            "posting_date" date,
            "value_date" date,
            "remittance_information" varchar NOT NULL,
            "payment_type" varchar,
            "external_ref" varchar,
            "channel" varchar,
            "internal_note" varchar
          );
        )

        m << %(CREATE INDEX ledger_transaction_entries_transaction_id_idx ON "projections"."ledger_transaction_entries"(transaction_id);)

        m.each { |s| @projection_database.exec s }
      end

      def apply(event : ::Ledger::Transactions::Request::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

        aggregate = ::Ledger::Transactions::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        entries = aggregate.state.entries
        currency = aggregate.state.currency
        posting_date = aggregate.state.posting_date
        value_date = aggregate.state.value_date
        remittance_information = aggregate.state.remittance_information
        payment_type = aggregate.state.payment_type
        external_ref = aggregate.state.external_ref
        channel = aggregate.state.channel
        internal_note = aggregate.state.internal_note

        raise "Invalid ledger transaction state: missing entries" if entries.nil?
        raise "Invalid ledger transaction state: missing currency" if currency.nil?
        raise "Invalid ledger transaction state: missing remittance_information" if remittance_information.nil?

        @projection_database.transaction do |tx|
          cnn = tx.connection
          entries.each do |entry|
            cnn.exec %(
              INSERT INTO
                "projections"."ledger_transaction_entries" (
                  transaction_id,
                  aggregate_version,
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
                  internal_note
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
            ),
              aggregate_id,
              aggregate_version,
              created_at,
              entry.account_id,
              entry.direction,
              entry.amount,
              entry.entry_type,
              currency,
              posting_date,
              value_date,
              remittance_information,
              payment_type,
              external_ref,
              channel,
              internal_note
          end
        end
      end
    end
  end
end
