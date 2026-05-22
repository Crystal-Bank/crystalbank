# Aggregate
require "./aggregates/account"
require "./aggregates/blocking_request"
require "./aggregates/unblocking_request"
require "./aggregates/closure_request"

# Virtual Accounts
require "./virtual_account/events/opening/requested"
require "./virtual_account/events/opening/accepted"
require "./virtual_account/aggregate"
require "./virtual_account/commands/opening/request"
require "./virtual_account/commands/opening/process_request"
require "./virtual_account/commands/opening/process_approval"
require "./virtual_account/projections/virtual_accounts"
require "./virtual_account/queries/virtual_accounts"
require "./virtual_account/api/virtual_accounts"

# API
require "./api/accounts"

# Commands
require "./commands/opening/request"
require "./commands/opening/process_request"
require "./commands/opening/process_approval"
require "./commands/blocking/block"
require "./commands/blocking/unblock"
require "./commands/blocking/process_block_approval"
require "./commands/blocking/process_unblock_approval"
require "./commands/closure/request"
require "./commands/closure/process_approval"

# Events
require "./events/opening/accepted"
require "./events/opening/requested"
require "./events/blocking/applied"
require "./events/blocking/removed"
require "./events/blocking/blocking/requested"
require "./events/blocking/blocking/completed"
require "./events/blocking/unblocking/requested"
require "./events/blocking/unblocking/completed"
require "./events/closure/requested"
require "./events/closure/accepted"
require "./events/closure/closure/requested"
require "./events/closure/closure/completed"

# Projections
require "./projections/accounts"
require "./projections/account_blocks"

# Queries
require "./queries/accounts"
require "./queries/account_blocks"

# Domain
require "./accounts"
