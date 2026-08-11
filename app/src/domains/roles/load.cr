# Aggregate
require "./aggregates/aggregate"
require "./aggregates/permissions_update"

# API
require "./api/roles"

# Commands
require "./commands/creation/request"
require "./commands/creation/accept"
require "./commands/permissions_update/request"
require "./commands/permissions_update/accept"

# Reactors
require "./reactors/creation/on_requested"
require "./reactors/creation/on_approval_completed"
require "./reactors/permissions_update/on_approval_completed"

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

# Domain
require "./roles"
