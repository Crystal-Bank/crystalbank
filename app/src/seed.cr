require "./load"

event_store = ES::Config.event_store

dummy_uuid = UUID.new("00000000-0000-0000-0000-000000000000")

api_secret = "secret"
api_secret_encrypted = Crypto::Bcrypt::Password.create(api_secret, cost: 10).to_s

# Create User
event = Users::Onboarding::Events::Requested.new(
  actor_id: dummy_uuid,
  command_handler: "seed",
  name: "Admin",
  email: "admin@crystalbank.xyz"
)

# Append event to event store
event_store.append(event)

# Return the aggregate ID of the newly created user aggregate
user_id = UUID.new(event.header.aggregate_id.to_s)

# Create API key          
event = ApiKeys::Generation::Events::Requested.new(
  actor_id: dummy_uuid,
  api_secret: api_secret_encrypted,
  command_handler: "seed",
  name: "admin api key",
  user_id: user_id
)

# Append event to event store
event_store.append(event)

# Return the aggregate ID of the newly created user aggregate
puts "API key"
puts UUID.new(event.header.aggregate_id.to_s)