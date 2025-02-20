require "spec"
require "../src/crystalbank"
require "./factories/events/account_factories"
require "./factories/events/api_key_factories"
require "./factories/events/customer_factories"
require "./factories/events/scope_factories"
require "./factories/events/transaction_factories"
require "./factories/events/user_factories"

TEST_EVENT_STORE   = ES::Config.event_store
TEST_PROJECTION_DB = ES::Config.projection_database
