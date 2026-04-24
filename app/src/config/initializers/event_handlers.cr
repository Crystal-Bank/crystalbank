# Initializing event handlers
ES::Config.event_handlers = ES::EventHandlers.new
event_handlers = ES::Config.event_handlers

# Accounts
event_handlers.register(Accounts::Opening::Events::Accepted)
event_handlers.register(Accounts::Opening::Events::Requested)

# Account Blocks
event_handlers.register(Accounts::Blocking::Events::Applied)
event_handlers.register(Accounts::Blocking::Events::Removed)

event_handlers.register(Accounts::Blocking::Blocking::Events::Requested)
event_handlers.register(Accounts::Blocking::Blocking::Events::Completed)
event_handlers.register(Accounts::Blocking::Unblocking::Events::Requested)
event_handlers.register(Accounts::Blocking::Unblocking::Events::Completed)

# Approvals
event_handlers.register(Approvals::Creation::Events::Requested)
event_handlers.register(Approvals::Collection::Events::Collected)
event_handlers.register(Approvals::Collection::Events::Completed)
event_handlers.register(Approvals::Rejection::Events::Rejected)

# ApiKeys
event_handlers.register(ApiKeys::Generation::Events::Accepted)
event_handlers.register(ApiKeys::Generation::Events::Requested)
event_handlers.register(ApiKeys::Revocation::Events::Accepted)
event_handlers.register(ApiKeys::Revocation::Events::Requested)

# Customers
event_handlers.register(Customers::Onboarding::Events::Accepted)
event_handlers.register(Customers::Onboarding::Events::Requested)

# Roles
event_handlers.register(Roles::Creation::Events::Accepted)
event_handlers.register(Roles::Creation::Events::Requested)
event_handlers.register(Roles::PermissionsUpdate::Events::Requested)
event_handlers.register(Roles::PermissionsUpdate::Events::Completed)
event_handlers.register(Roles::PermissionsUpdate::Events::Accepted)

# Scopes
event_handlers.register(Scopes::Creation::Events::Accepted)
event_handlers.register(Scopes::Creation::Events::Requested)

# Ledger
event_handlers.register(Ledger::Transactions::Request::Events::Accepted)
event_handlers.register(Ledger::Transactions::Request::Events::Requested)

# Payments - SEPA Credit Transfers
event_handlers.register(CrystalBank::Domains::Payments::Sepa::CreditTransfers::Initiation::Events::Accepted)
event_handlers.register(CrystalBank::Domains::Payments::Sepa::CreditTransfers::Initiation::Events::Requested)

# Users
event_handlers.register(Users::Onboarding::Events::Accepted)
event_handlers.register(Users::Onboarding::Events::Requested)
event_handlers.register(Users::AssignRoles::Events::Accepted)
event_handlers.register(Users::AssignRoles::Events::Requested)
event_handlers.register(Users::RemoveRoles::Events::Accepted)
event_handlers.register(Users::RemoveRoles::Events::Requested)
