# Define alias
alias Users = CrystalBank::Domains::Users

# Prepare projections
Users::Projections::Users.new.setup
Users::Projections::AssignRolesRequests.new.setup
