# Aggregate
require "./aggregates/aggregate"
require "./aggregates/name_change"

# API
require "./api/scopes"

# Commands
require "./commands/creation/request"
require "./commands/creation/process_request"
require "./commands/creation/process_approval"
require "./commands/name_change/request"
require "./commands/name_change/process_approval"

# Events
require "./events/creation/accepted"
require "./events/creation/requested"
require "./events/name_change/requested"
require "./events/name_change/accepted"
require "./events/name_change/completed"

# Projections
require "./projections/scopes"
require "./projections/scopes_name_changes"

# Queries
require "./queries/scopes"
require "./queries/scopes_tree"

# Domain
require "./scopes"
