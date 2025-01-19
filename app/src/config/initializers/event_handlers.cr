# Initializing event handlers
ES::Config.event_handlers = ES::EventHandlers.new
event_handlers = ES::Config.event_handlers

# Accounts
event_handlers.register(Accounts::Opening::Events::Accepted)
event_handlers.register(Accounts::Opening::Events::Requested)

# ApiKeys
event_handlers.register(ApiKeys::Generation::Events::Accepted)
event_handlers.register(ApiKeys::Generation::Events::Requested)
event_handlers.register(ApiKeys::Revocation::Events::Accepted)
event_handlers.register(ApiKeys::Revocation::Events::Requested)

# Customers
event_handlers.register(Customers::Onboarding::Events::Accepted)
event_handlers.register(Customers::Onboarding::Events::Requested)

# Scopes
event_handlers.register(Scopes::Creation::Events::Accepted)
event_handlers.register(Scopes::Creation::Events::Requested)

# Transactions
event_handlers.register(Transactions::InternalTransfers::Initiation::Events::Accepted)
event_handlers.register(Transactions::InternalTransfers::Initiation::Events::Requested)

# Users
event_handlers.register(Users::Onboarding::Events::Accepted)
event_handlers.register(Users::Onboarding::Events::Requested)
