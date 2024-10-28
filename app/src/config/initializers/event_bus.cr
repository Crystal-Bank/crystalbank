# Initialize event bus
ES::Config.event_bus = ES::EventBus(ES::Command.class | ES::Projection.class).new
bus = ES::Config.event_bus

# Subscribing command handlers to events
bus.subscribe(Accounts::Opening::Events::Requested, Accounts::Opening::Commands::ProcessRequest)
