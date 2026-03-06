# Aggregate
require "./aggregates/aggregate"

# API
require "./api/approvals"

# Commands
require "./commands/creation/request"
require "./commands/creation/process_request"
require "./commands/submission/request"
require "./commands/submission/process_request"
require "./commands/finalization/finalize"

# Events
require "./events/creation/accepted"
require "./events/creation/requested"
require "./events/submission/accepted"
require "./events/submission/all_approved"
require "./events/submission/rejected"
require "./events/submission/requested"

# Projections
require "./projections/approvals"

# Queries
require "./queries/approvals"

# Domain
require "./approvals"
