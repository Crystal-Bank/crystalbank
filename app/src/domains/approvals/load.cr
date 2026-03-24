# Aggregate
require "./aggregates/aggregate"

# API
require "./api/approvals"

# Commands
require "./commands/creation/request"
require "./commands/collection/request"
require "./commands/rejection/request"

# Events
require "./events/creation/requested"
require "./events/collection/collected"
require "./events/collection/completed"
require "./events/rejection/rejected"

# Projections
require "./projections/approvals"

# Queries
require "./queries/approvals"

# Domain
require "./approvals"
