# Aggregate
require "./aggregates/account"
require "./aggregates/blocking_request"
require "./aggregates/unblocking_request"
require "./aggregates/closure_request"

# API
require "./api/accounts"

# Commands
require "./commands/opening/request"
require "./commands/opening/accept"
require "./commands/blocking/block"
require "./commands/blocking/unblock"
require "./commands/blocking/apply"
require "./commands/blocking/remove"
require "./commands/closure/request"
require "./commands/closure/accept"

# Reactors
require "./reactors/opening/on_requested"
require "./reactors/opening/on_approval_completed"
require "./reactors/blocking/on_block_approval_completed"
require "./reactors/blocking/on_unblock_approval_completed"
require "./reactors/closure/on_approval_completed"

# Events
require "./events/opening/accepted"
require "./events/opening/requested"
require "./events/blocking/applied"
require "./events/blocking/removed"
require "./events/blocking_request/requested"
require "./events/blocking_request/completed"
require "./events/unblocking_request/requested"
require "./events/unblocking_request/completed"
require "./events/closure/requested"
require "./events/closure/accepted"
require "./events/closure_request/requested"
require "./events/closure_request/completed"

# Projections
require "./projections/accounts"
require "./projections/account_blocks"

# Queries
require "./queries/accounts"
require "./queries/account_blocks"

# Domain
require "./accounts"
