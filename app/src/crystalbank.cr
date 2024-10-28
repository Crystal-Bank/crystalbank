# Load libs
require "db"
require "pg"
require "crystal-es"

# Load config
require "./config/load"

# Load domains
require "./domains/accounts/load"

module Crystalbank
  VERSION = "0.1.0"
end
