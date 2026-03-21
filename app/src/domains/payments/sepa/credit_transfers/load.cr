# Aggregate
require "./aggregates/aggregate"

# API
require "./api/credit_transfers"

# Commands
require "./commands/initiation/request"
require "./commands/execution/process_approval"

# Events
require "./events/initiation/requested"
require "./events/execution/executed"

# Projections
require "./projections/credit_transfers"

# Queries
require "./queries/credit_transfers"

# Domain (aliases + projection setup)
require "./credit_transfers"
