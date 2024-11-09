# Define alias
alias Transactions::InternalTransfers = CrystalBank::Domains::Transactions::InternalTransfers

# Prepare projections
Transactions::InternalTransfers::Projections::Postings.new.prepare
