# Aggregate
require "./aggregates/aggregate"

# API
require "./api/roles"

# Commands
require "./commands/creation/request"
require "./commands/creation/process_request"
require "./commands/creation/process_approval"
require "./commands/permissions_update/request"
require "./commands/permissions_update/process_request"
require "./commands/permissions_update/process_approval"

# Events
require "./events/creation/accepted"
require "./events/creation/requested"
require "./events/permissions_update/requested"
require "./events/permissions_update/accepted"

# Projections
require "./projections/roles"

# Queries
require "./queries/roles"
require "./queries/roles_permissions"

# Domain
require "./roles"
