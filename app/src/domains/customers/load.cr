# Aggregate
require "./aggregates/aggregate"

# API
require "./api/customers"

# Commands
require "./commands/onboarding/request"
require "./commands/onboarding/process_request"

# Events
require "./events/onboarding/accepted"
require "./events/onboarding/requested"

# Projections
require "./projections/customers"

# Queries
require "./queries/customers"

# Domain
require "./customers"
