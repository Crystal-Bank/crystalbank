# Initialize event bus
ES::Config.event_bus = ES::EventBus(ES::Command.class | ES::Projection.class).new
bus = ES::Config.event_bus

# Subscribing command handlers to events

# Accounts
bus.subscribe(Accounts::Opening::Events::Requested, Accounts::Opening::Commands::ProcessRequest)
bus.subscribe(Accounts::Opening::Events::Accepted, Accounts::Projections::Accounts)

# Approvals
bus.subscribe(Approvals::Creation::Events::Requested, Approvals::Projections::Approvals)
bus.subscribe(Approvals::Collection::Events::Collected, Approvals::Projections::Approvals)
bus.subscribe(Approvals::Collection::Events::Completed, Approvals::Projections::Approvals)
bus.subscribe(Approvals::Collection::Events::Completed, Accounts::Opening::Commands::ProcessApproval)
bus.subscribe(Approvals::Collection::Events::Completed, Payments::Sepa::CreditTransfers::Initiation::Commands::ProcessApproval)

# ApiKeys
bus.subscribe(ApiKeys::Generation::Events::Requested, ApiKeys::Generation::Commands::ProcessRequest)
bus.subscribe(ApiKeys::Generation::Events::Accepted, ApiKeys::Projections::ApiKeys)
bus.subscribe(ApiKeys::Revocation::Events::Requested, ApiKeys::Revocation::Commands::ProcessRequest)
bus.subscribe(ApiKeys::Revocation::Events::Accepted, ApiKeys::Projections::ApiKeys)

# Customers
bus.subscribe(Customers::Onboarding::Events::Requested, Customers::Onboarding::Commands::ProcessRequest)
bus.subscribe(Customers::Onboarding::Events::Accepted, Customers::Projections::Customers)

# Roles
bus.subscribe(Roles::Creation::Events::Requested, Roles::Creation::Commands::ProcessRequest)
bus.subscribe(Roles::Creation::Events::Accepted, Roles::Projections::Roles)

# Scopes
bus.subscribe(Scopes::Creation::Events::Requested, Scopes::Creation::Commands::ProcessRequest)
bus.subscribe(Scopes::Creation::Events::Accepted, Scopes::Projections::Scopes)

# Ledger
bus.subscribe(Ledger::Transactions::Request::Events::Requested, Ledger::Transactions::Request::Commands::ProcessRequest)
bus.subscribe(Ledger::Transactions::Request::Events::Accepted, Ledger::Transactions::Projections::Postings)

# Payments — SEPA Credit Transfers
bus.subscribe(Payments::Sepa::CreditTransfers::Initiation::Events::Requested, Payments::Sepa::CreditTransfers::Projections::CreditTransfers)
bus.subscribe(Payments::Sepa::CreditTransfers::Initiation::Events::Accepted, Payments::Sepa::CreditTransfers::Projections::CreditTransfers)

# Transactions (internal_transfers commented out pending redesign to write to postings)
# bus.subscribe(Transactions::InternalTransfers::Initiation::Events::Requested, Transactions::InternalTransfers::Initiation::Commands::ProcessRequest)
# bus.subscribe(Transactions::InternalTransfers::Initiation::Events::Accepted, Transactions::InternalTransfers::Projections::Postings)

# Users
bus.subscribe(Users::Onboarding::Events::Requested, Users::Onboarding::Commands::ProcessRequest)
bus.subscribe(Users::Onboarding::Events::Accepted, Users::Projections::Users)
bus.subscribe(Users::AssignRoles::Events::Requested, Users::AssignRoles::Commands::ProcessRequest)
bus.subscribe(Users::AssignRoles::Events::Accepted, Users::Projections::Users)
