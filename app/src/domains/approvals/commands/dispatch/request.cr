# This file is intentionally left as a stub.
# Dispatch logic is handled inline in Approvals::Decide::Commands::Request
# to avoid requiring multiple event bus subscribers for a single event type.
#
# If the crystal-es EventBus is confirmed to support multiple subscribers per event,
# the dispatch table can be extracted here and wired via:
#   bus.subscribe(Approvals::Workflow::Events::Completed, Approvals::Dispatch::Commands::Request)
