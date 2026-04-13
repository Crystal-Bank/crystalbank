# Aggregate
require "./aggregates/aggregate"
require "./aggregates/permissions_update"

# API
require "./api/roles"

# Commands
require "./commands/creation/request"
require "./commands/creation/process_request"
require "./commands/creation/process_approval"
require "./commands/permissions_update/request"
require "./commands/permissions_update/process_approval"

# Events
require "./events/creation/accepted"
require "./events/creation/requested"
require "./events/permissions_update/requested"
require "./events/permissions_update/completed"
require "./events/permissions_update/accepted"

# Projections
require "./projections/roles"
require "./projections/roles_permissions_updates"

# Queries
require "./queries/roles"
require "./queries/roles_permissions"
require "./queries/find_role"

# Domain
require "./roles"
