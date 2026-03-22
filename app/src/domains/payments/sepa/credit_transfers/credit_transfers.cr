# Define alias
alias Payments::Sepa::CreditTransfers = CrystalBank::Domains::Payments::Sepa::CreditTransfers

# Prepare projections
Payments::Sepa::CreditTransfers::Projections::CreditTransfers.new.prepare
