# Aggregate
require "./aggregates/aggregate"

# API
require "./api/advices"

# Commands
require "./commands/advice/process"
require "./commands/advice_response/process"

# Events
require "./events/advice/received"
require "./events/advice_response/accepted"
require "./events/advice_response/rejected"

# Projections
require "./projections/advices"

# Queries
require "./queries/advices"

# Domain aliases + projection setup
require "./advices"
