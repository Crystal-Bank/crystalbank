# Aggregate
require "./aggregates/aggregate"

# API
require "./api/approvals"

# Commands
require "./commands/initiate/request"
require "./commands/decide/request"
require "./commands/dispatch/request"

# Events
require "./events/workflow/initiated"
require "./events/workflow/completed"
require "./events/decision/made"

# Projections
require "./projections/approvals"

# Queries
require "./queries/approvals"

# Domain
require "./approvals"
