# Initialize event bus
ES::Config.event_bus = ES::EventBus(ES::Command.class | ES::Projection.class).new
bus = ES::Config.event_bus

# Subscribing command handlers to events

# Accounts
bus.subscribe(Accounts::Opening::Events::Requested, Accounts::Opening::Commands::ProcessRequest)
bus.subscribe(Accounts::Opening::Events::Accepted, Accounts::Projections::Accounts)

# ApiKeys
bus.subscribe(ApiKeys::Generation::Events::Requested, ApiKeys::Generation::Commands::ProcessRequest)
bus.subscribe(ApiKeys::Generation::Events::Accepted, ApiKeys::Projections::ApiKeys)

# Customers
bus.subscribe(Customers::Onboarding::Events::Requested, Customers::Onboarding::Commands::ProcessRequest)
bus.subscribe(Customers::Onboarding::Events::Accepted, Customers::Projections::Customers)

# Transactions
bus.subscribe(Transactions::InternalTransfers::Initiation::Events::Requested, Transactions::InternalTransfers::Initiation::Commands::ProcessRequest)
bus.subscribe(Transactions::InternalTransfers::Initiation::Events::Accepted, Transactions::InternalTransfers::Projections::Postings)

# Users
bus.subscribe(Users::Onboarding::Events::Requested, Users::Onboarding::Commands::ProcessRequest)
bus.subscribe(Users::Onboarding::Events::Accepted, Users::Projections::Users)
