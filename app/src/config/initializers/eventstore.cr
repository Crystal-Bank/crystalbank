# Initializing eventstore
ES::Config.event_store = ES::EventStoreAdapters::Postgres.new(DB.open(CrystalBank::Env.eventstore_uri))
ES::Config.event_store.setup
