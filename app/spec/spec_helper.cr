require "spec"
require "../src/crystalbank"
require "./factories/events/account_factories"
require "./factories/events/approval_factories"
require "./factories/events/api_key_factories"
require "./factories/events/customer_factories"
require "./factories/events/role_factories"
require "./factories/events/scope_factories"
require "./factories/events/ledger_transaction_factories"
require "./factories/events/payment_sepa_credit_transfer_factories"
require "./factories/events/user_factories"

TEST_EVENT_STORE   = ES::Config.event_store
TEST_PROJECTION_DB = ES::Config.projection_database

# Replays all events for an aggregate through the event bus, applying any
# registered projections synchronously. Use this in tests after running a
# command whose internal events would otherwise only be projected asynchronously
# via the queue.
def apply_projection(aggregate_id : UUID)
  TEST_EVENT_STORE.fetch_events(aggregate_id).each do |raw|
    h = ES::Event::Header.from_json(raw.header.to_json)
    event = ES::Config.event_handlers.event_class(h.event_handle).new(h, raw.body)
    ES::Config.event_bus.publish(event)
  end
end
