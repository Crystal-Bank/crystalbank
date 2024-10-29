# Define alias
alias Accounts = CrystalBank::Domains::Accounts

# Api
# require "./api/accounts"

# Aggregate
require "./aggregate"

# Commands
require "./commands/opening/request"
require "./commands/opening/process_request"

# Events
require "./events/opening/accepted"
require "./events/opening/requested"
