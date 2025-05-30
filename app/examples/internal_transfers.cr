require "../src/crystalbank"

# ---------------------------------------------------------
# This showcases
#  - the onboarding of a customer
#  - the opening of two accounts, debtor and creditor
#  - internal transfers between the two accounts
#  - projection into the "projections"."accounts" table
#  - projection into the "projections"."postings" table
# ---------------------------------------------------------

NUMBER_OF_TRANSFERS = 1000

puts "Create customer"
customer_onboarding_request = Customers::Api::Requests::OnboardingRequest.from_json(%({"name": "John Doe", "type": "individual"}))
customer_id = Customers::Onboarding::Commands::Request.new.call(customer_onboarding_request)

# Wait 10 seconds until customer is fully onboarded
puts "Waiting for customer onboarding requests to be accepted"
customer_onboarded = false
attempt = 0
while !customer_onboarded && attempt < 10
  customer_aggregate = Customers::Aggregate.new(customer_id)
  customer_aggregate.hydrate
  customer_onboarded = customer_aggregate.state.onboarded

  attempt += 1
  puts "Check if customer is fully onboarded, attempt no: #{attempt}"
  sleep 1.seconds
end

puts "Opening debtor and creditor account"
creditor_account_opening_request = Accounts::Api::Requests::OpeningRequest.from_json(%({"currencies": ["eur", "usd", "jpy"], "type": "checking", "customer_ids": ["#{customer_id}"]}))
creditor_account_id = Accounts::Opening::Commands::Request.new.call(creditor_account_opening_request)

debtor_account_opening_request = Accounts::Api::Requests::OpeningRequest.from_json(%({"currencies": ["eur", "usd"], "type": "checking", "customer_ids": ["#{customer_id}"]}))
debtor_account_id = Accounts::Opening::Commands::Request.new.call(debtor_account_opening_request)
puts "Account opening requested: Creditor account ID: #{creditor_account_id}, Debtor account ID: #{debtor_account_id}"

# Wait 10 seconds until debtor and creditor account is open
puts "Waiting for account opening requests to be accepted"
creditor_account_open = false
debtor_account_open = false
attempt = 0
while (!creditor_account_open || !debtor_account_open) && attempt < 10
  creditor_account_aggregate = Accounts::Aggregate.new(creditor_account_id)
  creditor_account_aggregate.hydrate
  creditor_account_open = creditor_account_aggregate.state.open

  debtor_account_aggregate = Accounts::Aggregate.new(debtor_account_id)
  debtor_account_aggregate.hydrate
  debtor_account_open = debtor_account_aggregate.state.open

  attempt += 1
  puts "Check if debtor and creditor account is open, attempt no: #{attempt}"
  sleep 1.seconds
end

puts "#{Time.utc} - Performing #{NUMBER_OF_TRANSFERS} internal transfer requests"
NUMBER_OF_TRANSFERS.times do |i|
  r = Transactions::InternalTransfers::Api::Requests::InitiationRequest.from_json(%(
    {
      "amount": #{i + 1},
      "creditor_account_id": "#{creditor_account_id.to_s}",
      "currency": "eur",
      "debtor_account_id": "#{debtor_account_id.to_s}",
      "remittance_information": "Transfer no: #{i + 1}"
    }
  ))

  puts "Performing transfer #{i + 1}"
  Transactions::InternalTransfers::Initiation::Commands::Request.new.call(r)
  # sleep 20.milliseconds
end
puts "#{Time.utc} - #{NUMBER_OF_TRANSFERS} internal transfer requests performed"

puts "Press any key to exit"
gets
