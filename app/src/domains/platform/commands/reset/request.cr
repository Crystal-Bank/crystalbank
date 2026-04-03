module CrystalBank::Domains::Platform
  module Reset
    module Commands
      class Request < ES::Command
        PROJECTION_TABLES = %w[
          account_blocks accounts api_keys approvals customers events
          postings roles scopes sepa_credit_transfers users
        ]

        def call : CrystalBank::Domains::Platform::Api::Responses::ResetResponse
          db = ES::Config.projection_database

          # Truncate all projection tables
          PROJECTION_TABLES.each do |table|
            db.exec %(TRUNCATE "projections"."#{table}" RESTART IDENTITY CASCADE)
          end

          # Truncate event store (public schema)
          db.exec %(TRUNCATE events RESTART IDENTITY CASCADE)

          # Purge PGMQ queue to drop stale messages
          db.exec %(SELECT pgmq.purge_queue('default'))

          # Re-seed the platform
          CrystalBank::Domains::Platform::SeedService.new(@event_store).call
        end
      end
    end
  end
end
