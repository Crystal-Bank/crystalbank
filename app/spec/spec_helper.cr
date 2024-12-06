require "spec"
require "../src/crystalbank"
require "./factories/events/account_factories"
require "./factories/events/customer_factories"
require "./factories/events/transaction_factories"

TEST_EVENT_STORE   = ES::Config.event_store
TEST_PROJECTION_DB = ES::Config.projection_database
