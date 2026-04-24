# Define alias
alias Credentials = CrystalBank::Domains::Credentials

# Prepare projections
Credentials::Projections::Credentials.new.prepare
