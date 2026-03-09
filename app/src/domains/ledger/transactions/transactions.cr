# Define alias
alias Ledger::Transactions = CrystalBank::Domains::Ledger::Transactions

# Prepare projections
Ledger::Transactions::Projections::LedgerTransactionEntries.new.prepare
