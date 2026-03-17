module CrystalBank::Domains::Ledger::Transactions
  module Projections
    class Postings < ES::Projection
      def prepare
        exists = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename = 'postings');), as: Bool

        if exists
          id_is_uuid = @projection_database.query_one %(
            SELECT data_type = 'uuid' FROM information_schema.columns
            WHERE table_schema = 'projections' AND table_name = 'postings' AND column_name = 'id'
          ), as: Bool
          return true if id_is_uuid

          @projection_database.exec %(DROP TABLE "projections"."postings")
        end

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."postings" (
            "id" UUID PRIMARY KEY,
            "transaction_id" UUID NOT NULL,
            "aggregate_version" int8 NOT NULL,
            "scope_id" UUID NOT NULL,
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
            "channel" varchar
          );
        )

        m << %(CREATE INDEX postings_transaction_id_idx ON "projections"."postings"(transaction_id);)

        m.each { |s| @projection_database.exec s }
      end

      def apply(event : ::Ledger::Transactions::Request::Events::Accepted)
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version
        created_at = event.header.created_at

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
                  channel
                )
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
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
              channel
          end
        end
      end
    end
  end
end
