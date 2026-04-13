# Domain (defines Platform alias used by API and commands)
require "./platform"

# Queries
require "./queries/types"
require "./queries/permission_groups"

# Commands
require "./commands/seed/service"
require "./commands/reset/request"
require "./commands/types/fetch_permissions"
require "./commands/types/fetch_account_types"
require "./commands/types/fetch_currencies"
require "./commands/types/fetch_customer_types"
require "./commands/types/fetch_ledger_entry_types"
require "./commands/types/fetch_permission_groups"

# API
require "./api/platform"
require "./api/types"
