# Define alias
alias Accounts = CrystalBank::Domains::Accounts

# Prepare projections
Accounts::Projections::Accounts.new.setup
Accounts::Projections::AccountBlocks.new.setup
