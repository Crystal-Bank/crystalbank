# Define alias
alias Roles = CrystalBank::Domains::Roles

# Prepare projections
Roles::Projections::Roles.new.prepare
