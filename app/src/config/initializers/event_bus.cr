# Initialize event bus
ES::Config.event_bus = ES::EventBus(ES::Reactor.class | ES::Projection.class).new
bus = ES::Config.event_bus

# Subscribing reactors and projections to events

# Accounts
bus.subscribe(Accounts::Opening::Events::Requested, Accounts::Reactors::Opening::OnRequested)
bus.subscribe(Accounts::Opening::Events::Requested, Accounts::Projections::Accounts)
bus.subscribe(Accounts::Opening::Events::Accepted, Accounts::Projections::Accounts)

# Virtual Accounts
bus.subscribe(VirtualAccounts::Opening::Events::Requested, VirtualAccounts::Reactors::Opening::OnRequested)
bus.subscribe(VirtualAccounts::Opening::Events::Requested, VirtualAccounts::Projections::VirtualAccounts)
bus.subscribe(VirtualAccounts::Opening::Events::Accepted, VirtualAccounts::Projections::VirtualAccounts)
bus.subscribe(Approvals::Collection::Events::Completed, VirtualAccounts::Reactors::Opening::OnApprovalCompleted)

# Account Closure
bus.subscribe(Accounts::Closure::Events::Requested, Accounts::Projections::Accounts)
bus.subscribe(Accounts::Closure::Events::Accepted, Accounts::Projections::Accounts)
bus.subscribe(Approvals::Collection::Events::Completed, Accounts::Reactors::Closure::OnApprovalCompleted)

# Account Blocks
bus.subscribe(Accounts::Blocking::Events::Applied, Accounts::Projections::AccountBlocks)
bus.subscribe(Accounts::Blocking::Events::Removed, Accounts::Projections::AccountBlocks)
bus.subscribe(Approvals::Collection::Events::Completed, Accounts::Reactors::Blocking::OnBlockApprovalCompleted)
bus.subscribe(Approvals::Collection::Events::Completed, Accounts::Reactors::Blocking::OnUnblockApprovalCompleted)

# Approvals
bus.subscribe(Approvals::Creation::Events::Requested, Approvals::Projections::Approvals)
bus.subscribe(Approvals::Collection::Events::Collected, Approvals::Projections::Approvals)
bus.subscribe(Approvals::Rejection::Events::Rejected, Approvals::Projections::Approvals)
bus.subscribe(Approvals::Collection::Events::Completed, Approvals::Projections::Approvals)
bus.subscribe(Approvals::Collection::Events::Completed, Accounts::Reactors::Opening::OnApprovalCompleted)
bus.subscribe(Approvals::Collection::Events::Completed, Payments::Sepa::CreditTransfers::Reactors::Initiation::OnApprovalCompleted)
bus.subscribe(Approvals::Collection::Events::Completed, Users::Reactors::Onboarding::OnApprovalCompleted)
bus.subscribe(Approvals::Collection::Events::Completed, Users::Reactors::AssignRoles::OnApprovalCompleted)
bus.subscribe(Approvals::Rejection::Events::Rejected, Users::Reactors::AssignRoles::OnRejected)
bus.subscribe(Approvals::Collection::Events::Completed, Users::Reactors::RemoveRoles::OnApprovalCompleted)

# ApiKeys
bus.subscribe(ApiKeys::Generation::Events::Requested, ApiKeys::Reactors::Generation::OnRequested)
bus.subscribe(ApiKeys::Generation::Events::Requested, ApiKeys::Projections::ApiKeys)
bus.subscribe(ApiKeys::Generation::Events::Accepted, ApiKeys::Projections::ApiKeys)
bus.subscribe(Approvals::Collection::Events::Completed, ApiKeys::Reactors::Generation::OnApprovalCompleted)
bus.subscribe(ApiKeys::Revocation::Events::Requested, ApiKeys::Reactors::Revocation::OnRequested)
bus.subscribe(ApiKeys::Revocation::Events::Accepted, ApiKeys::Projections::ApiKeys)

# Customers
bus.subscribe(Customers::Onboarding::Events::Requested, Customers::Reactors::Onboarding::OnRequested)
bus.subscribe(Customers::Onboarding::Events::Requested, Customers::Projections::Customers)
bus.subscribe(Customers::Onboarding::Events::Accepted, Customers::Projections::Customers)
bus.subscribe(Approvals::Collection::Events::Completed, Customers::Reactors::Onboarding::OnApprovalCompleted)

# Roles
bus.subscribe(Roles::Creation::Events::Requested, Roles::Reactors::Creation::OnRequested)
bus.subscribe(Roles::Creation::Events::Requested, Roles::Projections::Roles)
bus.subscribe(Roles::Creation::Events::Accepted, Roles::Projections::Roles)
bus.subscribe(Approvals::Collection::Events::Completed, Roles::Reactors::Creation::OnApprovalCompleted)

# Roles — Permissions Update
bus.subscribe(Roles::PermissionsUpdate::Events::Requested, Roles::Projections::RolesPermissionsUpdates)
bus.subscribe(Roles::PermissionsUpdate::Events::Completed, Roles::Projections::RolesPermissionsUpdates)
bus.subscribe(Roles::PermissionsUpdate::Events::Accepted, Roles::Projections::Roles)
bus.subscribe(Approvals::Collection::Events::Completed, Roles::Reactors::PermissionsUpdate::OnApprovalCompleted)

# Scopes
bus.subscribe(Scopes::Creation::Events::Requested, Scopes::Reactors::Creation::OnRequested)
bus.subscribe(Scopes::Creation::Events::Requested, Scopes::Projections::Scopes)
bus.subscribe(Scopes::Creation::Events::Accepted, Scopes::Projections::Scopes)
bus.subscribe(Approvals::Collection::Events::Completed, Scopes::Reactors::Creation::OnApprovalCompleted)

# Scopes — Name Change
bus.subscribe(Scopes::NameChange::Events::Accepted, Scopes::Projections::Scopes)
bus.subscribe(Approvals::Collection::Events::Completed, Scopes::Reactors::NameChange::OnApprovalCompleted)

# Ledger
bus.subscribe(Ledger::Transactions::Request::Events::Requested, Ledger::Transactions::Reactors::Request::OnRequested)
bus.subscribe(Ledger::Transactions::Request::Events::Accepted, Ledger::Transactions::Projections::Postings)

# Payments — SEPA Credit Transfers
bus.subscribe(Payments::Sepa::CreditTransfers::Initiation::Events::Requested, Payments::Sepa::CreditTransfers::Projections::CreditTransfers)
bus.subscribe(Payments::Sepa::CreditTransfers::Initiation::Events::Accepted, Payments::Sepa::CreditTransfers::Projections::CreditTransfers)

# Users
bus.subscribe(Users::Onboarding::Events::Requested, Users::Reactors::Onboarding::OnRequested)
bus.subscribe(Users::Onboarding::Events::Requested, Users::Projections::Users)
bus.subscribe(Users::Onboarding::Events::Accepted, Users::Projections::Users)
bus.subscribe(Users::AssignRoles::Events::Requested, Users::Reactors::AssignRoles::OnRequested)
bus.subscribe(Users::AssignRoles::Events::Requested, Users::Projections::AssignRolesRequests)
bus.subscribe(Users::AssignRoles::Events::Completed, Users::Projections::AssignRolesRequests)
bus.subscribe(Users::AssignRoles::Events::Rejected, Users::Projections::AssignRolesRequests)
bus.subscribe(Users::AssignRoles::Events::Accepted, Users::Projections::Users)
bus.subscribe(Users::RemoveRoles::Events::Requested, Users::Reactors::RemoveRoles::OnRequested)
bus.subscribe(Users::RemoveRoles::Events::Accepted, Users::Projections::Users)

# Events (cross-cutting audit projection)
bus.subscribe(Accounts::Opening::Events::Requested, Events::Projections::Events)
bus.subscribe(Accounts::Opening::Events::Accepted, Events::Projections::Events)
bus.subscribe(Accounts::Closure::Events::Requested, Events::Projections::Events)
bus.subscribe(Accounts::Closure::Events::Accepted, Events::Projections::Events)
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
bus.subscribe(Roles::PermissionsUpdate::Events::Requested, Events::Projections::Events)
bus.subscribe(Roles::PermissionsUpdate::Events::Accepted, Events::Projections::Events)
bus.subscribe(Scopes::Creation::Events::Requested, Events::Projections::Events)
bus.subscribe(Scopes::Creation::Events::Accepted, Events::Projections::Events)
bus.subscribe(Scopes::NameChange::Events::Requested, Events::Projections::Events)
bus.subscribe(Scopes::NameChange::Events::Accepted, Events::Projections::Events)
bus.subscribe(Users::Onboarding::Events::Requested, Events::Projections::Events)
bus.subscribe(Users::Onboarding::Events::Accepted, Events::Projections::Events)
bus.subscribe(Users::AssignRoles::Events::Requested, Events::Projections::Events)
bus.subscribe(Users::AssignRoles::Events::Accepted, Events::Projections::Events)
bus.subscribe(Users::AssignRoles::Events::Completed, Events::Projections::Events)
bus.subscribe(Users::AssignRoles::Events::Rejected, Events::Projections::Events)
bus.subscribe(Users::RemoveRoles::Events::Requested, Events::Projections::Events)
bus.subscribe(Users::RemoveRoles::Events::Accepted, Events::Projections::Events)
bus.subscribe(Users::RemoveRoles::Events::Completed, Events::Projections::Events)
