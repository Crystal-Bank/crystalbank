# Aggregate
require "./aggregates/aggregate"

# API
require "./api/authorizations"

# Commands
require "./commands/request/process"
require "./commands/response/process"

# Events
require "./events/request/received"
require "./events/response/approved"
require "./events/response/declined"

# Projections
require "./projections/authorizations"

# Queries
require "./queries/authorizations"

# Domain aliases + projection setup
require "./authorizations"
