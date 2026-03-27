require "./crystalbank"

def seed_scope(event_store, actor_id, name, scope_id, parent_scope_id = nil, aggregate_id = nil)
  event = Scopes::Creation::Events::Requested.new(
    actor_id: actor_id,
    command_handler: "seed",
    name: name,
    parent_scope_id: parent_scope_id,
    scope_id: scope_id,
    aggregate_id: aggregate_id,
  )
  event_store.append(event)
  UUID.new(event.header.aggregate_id.to_s)
end

def seed_user(event_store, actor_id, name, email, scope_id)
  event = Users::Onboarding::Events::Requested.new(
    actor_id: actor_id,
    command_handler: "seed",
    name: name,
    email: email,
    scope_id: scope_id,
  )
  event_store.append(event)
  UUID.new(event.header.aggregate_id.to_s)
end

def seed_api_key(event_store, actor_id, name, user_id, scope_id, encrypted_secret)
  event = ApiKeys::Generation::Events::Requested.new(
    actor_id: actor_id,
    api_secret: encrypted_secret,
    command_handler: "seed",
    name: name,
    scope_id: scope_id,
    user_id: user_id,
  )
  event_store.append(event)
  UUID.new(event.header.aggregate_id.to_s)
end

def seed_role(event_store, actor_id, name, permissions, scope_id, scopes)
  event = Roles::Creation::Events::Requested.new(
    actor_id: actor_id,
    command_handler: "seed",
    name: name,
    permissions: permissions,
    scope_id: scope_id,
    scopes: scopes,
  )
  event_store.append(event)
  UUID.new(event.header.aggregate_id.to_s)
end

def assign_role(event_store, actor_id, user_id, role_id, scope_id, aggregate_version = 2)
  event = Users::AssignRoles::Events::Requested.new(
    actor_id: actor_id,
    command_handler: "seed",
    aggregate_id: user_id,
    aggregate_version: aggregate_version,
    role_ids: [role_id],
    scope_id: scope_id,
  )
  event_store.append(event)
end

def seed_account(event_store, actor_id, scope_id, name, customer_ids, currencies, type, aggregate_id)
  requested = Accounts::Opening::Events::Requested.new(
    actor_id: actor_id,
    command_handler: "seed",
    currencies: currencies,
    customer_ids: customer_ids,
    name: name,
    scope_id: scope_id,
    type: type,
    aggregate_id: aggregate_id,
  )
  event_store.append(requested)

  accepted = Accounts::Opening::Events::Accepted.new(
    actor_id: actor_id,
    command_handler: "seed",
    aggregate_id: aggregate_id,
    aggregate_version: 2,
  )
  event_store.append(accepted)

  aggregate_id
end

def seed_customer(event_store, actor_id, name, scope_id, type)
  event = Customers::Onboarding::Events::Requested.new(
    actor_id: actor_id,
    command_handler: "seed",
    name: name,
    scope_id: scope_id,
    type: type
  )

  event_store.append(event)
  UUID.new(event.header.aggregate_id.to_s)
end

event_store = ES::Config.event_store
dummy_uuid = UUID.new("00000000-0000-0000-0000-000000000000")
actor_id = dummy_uuid
api_secret = "secret"
api_secret_encrypted = Crypto::Bcrypt::Password.create(api_secret, cost: 10).to_s

# Scopes
scopes = Hash(String, UUID).new
scopes["root"] = seed_scope(event_store, actor_id, name: "Root Scope", scope_id: UUID.new("00000000-0000-0000-0000-800000000001"), parent_scope_id: nil, aggregate_id: UUID.new("00000000-0000-0000-0000-800000000001"))
scopes["sub"] = seed_scope(event_store, actor_id, name: "Sub Scope", scope_id: scopes["root"], parent_scope_id: scopes["root"], aggregate_id: UUID.new("00000000-0000-0000-0000-800000000002"))
scopes["sub2"] = seed_scope(event_store, actor_id, name: "Sub Scope #2", scope_id: scopes["root"], parent_scope_id: scopes["root"], aggregate_id: UUID.new("00000000-0000-0000-0000-800000000003"))

# Users
users = Hash(String, UUID).new
users["admin"] = seed_user(event_store, actor_id, "Admin", "admin@crystalbank.xyz", scopes["root"])
users["approver"] = seed_user(event_store, actor_id, "Approver", "approver@crystalbank.xyz", scopes["root"])
users["scoped"] = seed_user(event_store, actor_id, "Scoped", "approver@crystalbank.xyz", scopes["sub"])

# API Keys
client_ids = Hash(String, UUID).new
client_ids["admin"] = seed_api_key(event_store, actor_id, "admin api key", users["admin"], scopes["root"], api_secret_encrypted)
client_ids["approver"] = seed_api_key(event_store, actor_id, "approver api key", users["approver"], scopes["root"], api_secret_encrypted)
client_ids["scoped"] = seed_api_key(event_store, actor_id, "scoped api key", users["scoped"], scopes["sub"], api_secret_encrypted)

# Roles
roles = Hash(String, UUID).new
roles["admin"] = seed_role(event_store, actor_id, name: "Admin Role", permissions: CrystalBank::Permissions.values, scope_id: scopes["root"], scopes: [scopes["root"]])
roles["scoped"] = seed_role(event_store, actor_id, name: "Scoped Role", permissions: CrystalBank::Permissions.values, scope_id: scopes["root"], scopes: [scopes["sub"]])

# Role assignments
assign_role(event_store, actor_id, users["admin"], roles["admin"], scopes["root"])
assign_role(event_store, actor_id, users["approver"], roles["admin"], scopes["root"])
assign_role(event_store, actor_id, users["scoped"], roles["scoped"], scopes["root"])

# Customers
customers = Hash(String, UUID).new
customers["admin"] = seed_customer(event_store, actor_id, name: "Admin customer", scope_id: scopes["root"], type: CrystalBank::Types::Customers::Type::Business)
customers["scoped"] = seed_customer(event_store, actor_id, name: "Scoped customer", scope_id: scopes["sub"], type: CrystalBank::Types::Customers::Type::Business)
customers["scoped2"] = seed_customer(event_store, actor_id, name: "Scoped customer #2", scope_id: scopes["sub2"], type: CrystalBank::Types::Customers::Type::Business)

# Accounts
sepa_nostro_account_id = UUID.new("00000000-0000-0000-0000-900000000001")
seed_account(
  event_store,
  actor_id,
  scope_id: scopes["root"],
  customer_ids: [customers["admin"]],
  currencies: [CrystalBank::Types::Currencies::Supported::EUR],
  name: "SEPA Settlement Account",
  type: CrystalBank::Types::Accounts::Type::Settlement,
  aggregate_id: sepa_nostro_account_id,
)

# Output
CrystalBank.print_verbose("Seed credentials Admin user", [
  "client_id: '#{client_ids["admin"]}'",
  "client_secret: '#{api_secret}'",
].join("\n"))

CrystalBank.print_verbose("Seed credentials Approver user", [
  "client_id: '#{client_ids["approver"]}'",
  "client_secret: '#{api_secret}'",
].join("\n"))

CrystalBank.print_verbose("Seed credentials Scoped user", [
  "client_id: '#{client_ids["scoped"]}'",
  "client_secret: '#{api_secret}'",
].join("\n"))

CrystalBank.print_verbose("Created roles", [
  "Admin Role: '#{roles["admin"]}'",
  "Scoped Role: '#{roles["scoped"]}'",
].join("\n"))

CrystalBank.print_verbose("Created scopes", [
  "Root Scope: '#{scopes["root"]}'",
  "Sub Scope: '#{scopes["sub"]}'",
  "Sub Scope #2: '#{scopes["sub2"]}'",
].join("\n"))

CrystalBank.print_verbose("Created accounts", [
  "SEPA Nostro Account: '#{sepa_nostro_account_id}'",
].join("\n"))

CrystalBank.print_verbose("Created customers", [
  "Admin Customer: '#{customers["admin"]}'",
  "Scope Customer: '#{customers["scoped"]}'",
  "Scope #2 Customer: '#{customers["scoped2"]}'",
].join("\n"))
