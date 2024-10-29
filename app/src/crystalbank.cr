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

module Crystalbank
  VERSION = "0.1.0"
end
