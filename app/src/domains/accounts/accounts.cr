# Define alias
alias Accounts = CrystalBank::Domains::Accounts

# Prepare projections
Accounts::Projections::Accounts.new.prepare
Accounts::Projections::AccountBlocks.new.prepare
Accounts::VirtualAccount::Projections::VirtualAccounts.new.prepare
