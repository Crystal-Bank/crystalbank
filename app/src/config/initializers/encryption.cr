# Initializing event encryption (crypto-shredding)
application_key = ES::ApplicationEncryptionKeyManager.new(CrystalBank::Env.application_encryption_key)
key_store = ES::KeyStoreAdapters::Postgres.new(DB.open(CrystalBank::Env.eventstore_uri))
key_store.setup

ES::Config.encryption = ES::EncryptionKeyManager.new(key_store, application_key)
