# Aggregate
require "./aggregates/aggregate"
require "./aggregates/name_change"

# API
require "./api/scopes"

# Commands
require "./commands/creation/request"
require "./commands/creation/accept"
require "./commands/name_change/request"
require "./commands/name_change/accept"

# Reactors
require "./reactors/creation/on_requested"
require "./reactors/creation/on_approval_completed"
require "./reactors/name_change/on_approval_completed"

# Events
require "./events/creation/accepted"
require "./events/creation/requested"
require "./events/name_change/requested"
require "./events/name_change/accepted"
require "./events/name_change/completed"

# Projections
require "./projections/scopes"

# Queries
require "./queries/scopes"
require "./queries/scopes_tree"

# Domain
require "./scopes"
