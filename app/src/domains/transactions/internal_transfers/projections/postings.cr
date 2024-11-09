module CrystalBank::Domains::Transactions::InternalTransfers
  module Projections
    class Postings < ES::Projection
      def prepare
        skip = @projection_database.query_one %(SELECT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'projections' AND tablename  = 'postings');), as: Bool
        return true if skip

        m = Array(String).new
        m << %(
          CREATE TABLE "projections"."postings" (
            "id" SERIAL PRIMARY KEY,
            "uuid" UUID NOT NULL,
            "aggregate_version" int8 NOT NULL,
            "created_at" timestamp NOT NULL,
            "account_id" UUID NOT NULL,
            "amount" Int8 NOT NULL,
            "creditor_account_id" UUID NOT NULL,
            "currency" varchar NOT NULL,
            "debtor_account_id" UUID NOT NULL,
            "remittance_information" varchar NOT NULL
          );
        )

        m << %(CREATE UNIQUE INDEX postings_uuid_account_id_idx ON "projections"."postings"(uuid, account_id);)

        m.each { |s| @projection_database.exec s }
      end

      # Created
      def apply(event : ::Transactions::InternalTransfers::Initiation::Events::Accepted)
        # Extract attributes to local variables
        uuid = event.header.event_id
        created_at = event.header.created_at
        aggregate_id = event.header.aggregate_id
        aggregate_version = event.header.aggregate_version

        # Build the account aggregate up to the version of the event
        aggregate = ::Transactions::InternalTransfers::Aggregate.new(aggregate_id)
        aggregate.hydrate(version: aggregate_version)

        # Extract attributes to local variables
        amount = aggregate.state.amount
        creditor_account_id = aggregate.state.creditor_account_id
        currency = aggregate.state.currency.to_s.downcase
        debtor_account_id = aggregate.state.debtor_account_id
        remittance_information = aggregate.state.remittance_information

        raise "TODO: Invalid amount" if amount.nil?

        # Insert DEBIT posting into postings projection
        @projection_database.transaction do |tx|
          cnn = tx.connection
          cnn.exec %(
            INSERT INTO
              "projections"."postings" (
                uuid,
                aggregate_version,
                created_at,
                account_id,
                amount,
                creditor_account_id,
                currency,
                debtor_account_id,
                remittance_information
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
          ),
            aggregate_id,
            aggregate_version,
            created_at,
            debtor_account_id,
            -amount,
            creditor_account_id,
            currency,
            debtor_account_id,
            remittance_information

          # Insert CREDIT posting into postings projection
          cnn.exec %(
            INSERT INTO
              "projections"."postings" (
                uuid,
                aggregate_version,
                created_at,
                account_id,
                amount,
                creditor_account_id,
                currency,
                debtor_account_id,
                remittance_information
              )
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
          ),
            aggregate_id,
            aggregate_version,
            created_at,
            creditor_account_id,
            amount,
            creditor_account_id,
            currency,
            debtor_account_id,
            remittance_information
        end
      end
    end
  end
end
