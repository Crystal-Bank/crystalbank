# Aggregate
require "./aggregates/aggregate"

# API
require "./api/users"
require "./api/me"

# Commands
require "./commands/assign_roles/request"
require "./commands/assign_roles/process_request"
require "./commands/remove_roles/request"
require "./commands/remove_roles/process_request"
require "./commands/onboarding/request"
require "./commands/onboarding/process_request"
require "./commands/onboarding/process_approval"

# Events
require "./events/assign_roles/accepted"
require "./events/assign_roles/requested"
require "./events/remove_roles/accepted"
require "./events/remove_roles/requested"
require "./events/onboarding/accepted"
require "./events/onboarding/requested"

# Projections
require "./projections/users"

# Queries
require "./queries/users"

# Queries
require "./repositories/roles"

# Domain
require "./users"
