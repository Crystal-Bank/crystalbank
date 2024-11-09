# Initialize event bus
ES::Config.event_bus = ES::EventBus(ES::Command.class | ES::Projection.class).new
bus = ES::Config.event_bus

# Subscribing command handlers to events

# Accounts
bus.subscribe(Accounts::Opening::Events::Requested, Accounts::Opening::Commands::ProcessRequest)
bus.subscribe(Accounts::Opening::Events::Accepted, Accounts::Projections::Accounts)

# Transactions
bus.subscribe(Transactions::InternalTransfers::Initiation::Events::Requested, Transactions::InternalTransfers::Initiation::Commands::ProcessRequest)
bus.subscribe(Transactions::InternalTransfers::Initiation::Events::Accepted, Transactions::InternalTransfers::Projections::Postings)
