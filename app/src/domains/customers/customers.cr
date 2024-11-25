# Define alias
alias Customers = CrystalBank::Domains::Customers

# Prepare projections
Customers::Projections::Customers.new.prepare
