# Initialize event bus
ES::Config.event_bus = ES::EventBus(ES::Command.class | ES::Projection.class).new
bus = ES::Config.event_bus

# Accounts
# Domain Requested events now route to the Approvals workflow (initiate approval)
# instead of directly auto-approving via ProcessRequest.
# ProcessRequest is called inline by Approvals::Decide::Commands::Request
# once the required number of approvers has been reached.
bus.subscribe(Accounts::Opening::Events::Requested, Approvals::Initiate::Commands::AccountsOpening)
bus.subscribe(Accounts::Opening::Events::Accepted, Accounts::Projections::Accounts)

# ApiKeys
bus.subscribe(ApiKeys::Generation::Events::Requested, Approvals::Initiate::Commands::ApiKeysGeneration)
bus.subscribe(ApiKeys::Generation::Events::Accepted, ApiKeys::Projections::ApiKeys)
bus.subscribe(ApiKeys::Revocation::Events::Requested, Approvals::Initiate::Commands::ApiKeysRevocation)
bus.subscribe(ApiKeys::Revocation::Events::Accepted, ApiKeys::Projections::ApiKeys)

# Customers
bus.subscribe(Customers::Onboarding::Events::Requested, Approvals::Initiate::Commands::CustomersOnboarding)
bus.subscribe(Customers::Onboarding::Events::Accepted, Customers::Projections::Customers)

# Roles
bus.subscribe(Roles::Creation::Events::Requested, Approvals::Initiate::Commands::RolesCreation)
bus.subscribe(Roles::Creation::Events::Accepted, Roles::Projections::Roles)

# Scopes
bus.subscribe(Scopes::Creation::Events::Requested, Approvals::Initiate::Commands::ScopesCreation)
bus.subscribe(Scopes::Creation::Events::Accepted, Scopes::Projections::Scopes)

# Transactions
bus.subscribe(Transactions::InternalTransfers::Initiation::Events::Requested, Approvals::Initiate::Commands::TransactionsInternalTransfersInitiation)
bus.subscribe(Transactions::InternalTransfers::Initiation::Events::Accepted, Transactions::InternalTransfers::Projections::Postings)

# Users
bus.subscribe(Users::Onboarding::Events::Requested, Approvals::Initiate::Commands::UsersOnboarding)
bus.subscribe(Users::Onboarding::Events::Accepted, Users::Projections::Users)
bus.subscribe(Users::AssignRoles::Events::Requested, Approvals::Initiate::Commands::UsersAssignRoles)
bus.subscribe(Users::AssignRoles::Events::Accepted, Users::Projections::Users)

# Approvals — each event type has exactly one subscriber (projection)
# The dispatch to domain ProcessRequest happens inline inside Decide::Commands::Request.
bus.subscribe(Approvals::Workflow::Events::Initiated, Approvals::Projections::Approvals)
bus.subscribe(Approvals::Decision::Events::Made, Approvals::Projections::Approvals)
bus.subscribe(Approvals::Workflow::Events::Completed, Approvals::Projections::Approvals)
