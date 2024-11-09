# Initializing event handlers
ES::Config.event_handlers = ES::EventHandlers.new
event_handlers = ES::Config.event_handlers

event_handlers.register(Accounts::Opening::Events::Accepted)
event_handlers.register(Accounts::Opening::Events::Requested)

event_handlers.register(Transactions::InternalTransfers::Initiation::Events::Accepted)
event_handlers.register(Transactions::InternalTransfers::Initiation::Events::Requested)
