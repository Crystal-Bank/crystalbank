# Aggregate
require "./aggregates/aggregate"
require "./aggregates/assign_roles_request"
require "./aggregates/remove_roles_request"

# API
require "./api/users"
require "./api/me"

# Commands
require "./commands/assign_roles/request"
require "./commands/assign_roles/accept"
require "./commands/assign_roles/reject"
require "./commands/remove_roles/request"
require "./commands/remove_roles/accept"
require "./commands/onboarding/request"
require "./commands/onboarding/accept"

# Reactors
require "./reactors/assign_roles/on_requested"
require "./reactors/assign_roles/on_approval_completed"
require "./reactors/assign_roles/on_rejected"
require "./reactors/remove_roles/on_requested"
require "./reactors/remove_roles/on_approval_completed"
require "./reactors/onboarding/on_requested"
require "./reactors/onboarding/on_approval_completed"

# Events
require "./events/assign_roles/accepted"
require "./events/assign_roles/completed"
require "./events/assign_roles/rejected"
require "./events/assign_roles/requested"
require "./events/remove_roles/accepted"
require "./events/remove_roles/completed"
require "./events/remove_roles/requested"
require "./events/onboarding/accepted"
require "./events/onboarding/requested"

# Projections
require "./projections/users"
require "./projections/assign_roles_requests"

# Queries
require "./queries/users"

# Queries
require "./repositories/roles"

# Domain
require "./users"
