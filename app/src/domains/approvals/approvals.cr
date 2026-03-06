# Define alias
alias Approvals = CrystalBank::Domains::Approvals

# Prepare projections
Approvals::Projections::Approvals.new.prepare
