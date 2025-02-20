require "./crystalbank"

event_store = ES::Config.event_store

dummy_uuid = UUID.new("00000000-0000-0000-0000-000000000000")

api_secret = "secret"
api_secret_encrypted = Crypto::Bcrypt::Password.create(api_secret, cost: 10).to_s

# +++++++++++++++++++++++
# User seed {START}
# +++++++++++++++++++++++
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
# +++++++++++++++++++++++
# User seed {END}
# +++++++++++++++++++++++

# +++++++++++++++++++++++
# API key seed {START}
# +++++++++++++++++++++++
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
# +++++++++++++++++++++++
# API key seed {END}
# +++++++++++++++++++++++

# +++++++++++++++++++++++
# Role seed {START}
# +++++++++++++++++++++++

# Create Role
event = Roles::Creation::Events::Requested.new(
  actor_id: dummy_uuid,
  command_handler: "seed",
  name: "Admin Role",
  permissions: CrystalBank::Permissions.values,
  scopes: [] of UUID # TODO: Add top level admin scope
)
# Append event to event store
event_store.append(event)
role_id = UUID.new(event.header.aggregate_id.to_s)
# +++++++++++++++++++++++
# Role seed {END}
# +++++++++++++++++++++++

# Return the aggregate ID of the newly created user aggregate
output = [
  "client_id: '#{UUID.new(event.header.aggregate_id.to_s)}'",
  "client_secret: 'secret'",
]
CrystalBank.print_verbose("Seed credentials", output.join("\n"))

entities = [
  "Admin Role: '#{role_id}'",
  "Root Scope: 'TBD'",
]
CrystalBank.print_verbose("Created entities", output.join("\n"))
