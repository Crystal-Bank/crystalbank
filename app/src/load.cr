# Load libs
require "pg"
require "yaml"
require "crystal-es"

# Load config
require "./config/load"

# Load shared resources
require "./shared/load"

# Load domains
require "./domains/accounts/load"
require "./domains/api_keys/load"
require "./domains/approvals/load"
require "./domains/customers/load"
require "./domains/roles/load"
require "./domains/scopes/load"
require "./domains/ledger/transactions/load"
require "./domains/users/load"
