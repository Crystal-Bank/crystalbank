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
bus.subscribe(Approvals::Rejection::Events::Rejected, Approvals::Projections::Approvals)
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

# Users
bus.subscribe(Users::Onboarding::Events::Requested, Users::Onboarding::Commands::ProcessRequest)
bus.subscribe(Users::Onboarding::Events::Accepted, Users::Projections::Users)
bus.subscribe(Users::AssignRoles::Events::Requested, Users::AssignRoles::Commands::ProcessRequest)
bus.subscribe(Users::AssignRoles::Events::Accepted, Users::Projections::Users)

# Events (cross-cutting audit projection)
bus.subscribe(Accounts::Opening::Events::Requested, Events::Projections::Events)
bus.subscribe(Accounts::Opening::Events::Accepted, Events::Projections::Events)
bus.subscribe(ApiKeys::Generation::Events::Requested, Events::Projections::Events)
bus.subscribe(ApiKeys::Generation::Events::Accepted, Events::Projections::Events)
bus.subscribe(ApiKeys::Revocation::Events::Requested, Events::Projections::Events)
bus.subscribe(ApiKeys::Revocation::Events::Accepted, Events::Projections::Events)
bus.subscribe(Approvals::Creation::Events::Requested, Events::Projections::Events)
bus.subscribe(Approvals::Collection::Events::Collected, Events::Projections::Events)
bus.subscribe(Approvals::Collection::Events::Completed, Events::Projections::Events)
bus.subscribe(Approvals::Rejection::Events::Rejected, Events::Projections::Events)
bus.subscribe(Customers::Onboarding::Events::Requested, Events::Projections::Events)
bus.subscribe(Customers::Onboarding::Events::Accepted, Events::Projections::Events)
bus.subscribe(Ledger::Transactions::Request::Events::Requested, Events::Projections::Events)
bus.subscribe(Ledger::Transactions::Request::Events::Accepted, Events::Projections::Events)
bus.subscribe(Payments::Sepa::CreditTransfers::Initiation::Events::Requested, Events::Projections::Events)
bus.subscribe(Payments::Sepa::CreditTransfers::Initiation::Events::Accepted, Events::Projections::Events)
bus.subscribe(Roles::Creation::Events::Requested, Events::Projections::Events)
bus.subscribe(Roles::Creation::Events::Accepted, Events::Projections::Events)
bus.subscribe(Scopes::Creation::Events::Requested, Events::Projections::Events)
bus.subscribe(Scopes::Creation::Events::Accepted, Events::Projections::Events)
bus.subscribe(Users::Onboarding::Events::Requested, Events::Projections::Events)
bus.subscribe(Users::Onboarding::Events::Accepted, Events::Projections::Events)
bus.subscribe(Users::AssignRoles::Events::Requested, Events::Projections::Events)
bus.subscribe(Users::AssignRoles::Events::Accepted, Events::Projections::Events)
