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
require "./domains/customers/load"
require "./domains/transactions/internal_transfers/load"
require "./domains/transactions/postings/load"
require "./domains/users/load"