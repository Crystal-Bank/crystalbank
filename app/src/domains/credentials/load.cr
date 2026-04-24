# Aggregate
require "./aggregates/aggregate"

# API
require "./api/authentication"
require "./api/credentials"

# Commands
require "./commands/invitation/send_email"
require "./commands/authentication/request"
require "./commands/password_setup/request"
require "./commands/password_reset/request"
require "./commands/password_reset/confirm"
require "./commands/totp/setup"
require "./commands/totp/confirm"

# Events
require "./events/invitation/sent"
require "./events/password_setup/completed"
require "./events/password_reset/requested"
require "./events/password_reset/confirmed"
require "./events/totp/setup_initiated"
require "./events/totp/enabled"

# Projections
require "./projections/credentials"

# Queries
require "./queries/credentials"

# Repositories
require "./repositories/users"

# Domain
require "./credentials"
