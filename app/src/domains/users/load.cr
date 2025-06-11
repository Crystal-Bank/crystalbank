# Aggregate
require "./aggregates/aggregate"

# API
require "./api/users"

# Commands
require "./commands/assign_roles/request"
require "./commands/assign_roles/process_request"
require "./commands/onboarding/request"
require "./commands/onboarding/process_request"

# Events
require "./events/assign_roles/accepted"
require "./events/assign_roles/requested"
require "./events/onboarding/accepted"
require "./events/onboarding/requested"

# Projections
require "./projections/users"

# Queries
require "./queries/users"

# Domain
require "./users"
