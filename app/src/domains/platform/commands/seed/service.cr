module CrystalBank::Domains::Platform
  class SeedService
    ROOT_SCOPE_ID = UUID.new("00000000-0000-0000-0000-800000000001")
    ACTOR_ID      = UUID.new("00000000-0000-0000-0000-000000000000")

    def initialize(@event_store : ES::EventStore = ES::Config.event_store)
    end

    def call : CrystalBank::Domains::Platform::Api::Responses::ResetResponse
      seed_scope(ROOT_SCOPE_ID, "CrystalBank", ROOT_SCOPE_ID)

      super_admin_id = seed_user("Super Admin", "superadmin@crystalbank.xyz", ROOT_SCOPE_ID)
      approver_id    = seed_user("Approver", "approver@crystalbank.xyz", ROOT_SCOPE_ID)
      role_id        = seed_role("Origin Role", CrystalBank::Permissions.values, ROOT_SCOPE_ID, [ROOT_SCOPE_ID])

      assign_role(super_admin_id, role_id, ROOT_SCOPE_ID)
      assign_role(approver_id, role_id, ROOT_SCOPE_ID)

      admin_key_id, admin_secret       = seed_api_key("origin api key", super_admin_id, ROOT_SCOPE_ID)
      approver_key_id, approver_secret = seed_api_key("origin api key", approver_id, ROOT_SCOPE_ID)

      CrystalBank::Domains::Platform::Api::Responses::ResetResponse.new(
        super_admin: CrystalBank::Domains::Platform::Api::Responses::Credential.new(admin_key_id, admin_secret),
        approver: CrystalBank::Domains::Platform::Api::Responses::Credential.new(approver_key_id, approver_secret),
      )
    end

    private def seed_scope(scope_id : UUID, name : String, aggregate_id : UUID, parent_scope_id : UUID? = nil) : UUID
      event = Scopes::Creation::Events::Requested.new(
        actor_id: ACTOR_ID,
        command_handler: self.class.to_s,
        name: name,
        parent_scope_id: parent_scope_id,
        scope_id: scope_id,
        aggregate_id: aggregate_id,
      )
      @event_store.append(event)
      @event_store.append(Scopes::Creation::Events::Accepted.new(
        actor_id: ACTOR_ID,
        aggregate_id: aggregate_id,
        aggregate_version: 2,
        command_handler: self.class.to_s,
      ))
      aggregate_id
    end

    private def seed_user(name : String, email : String, scope_id : UUID) : UUID
      event = Users::Onboarding::Events::Requested.new(
        actor_id: ACTOR_ID,
        command_handler: self.class.to_s,
        name: name,
        email: email,
        scope_id: scope_id,
      )
      @event_store.append(event)
      user_id = UUID.new(event.header.aggregate_id.to_s)
      @event_store.append(Users::Onboarding::Events::Accepted.new(
        actor_id: ACTOR_ID,
        aggregate_id: user_id,
        aggregate_version: 2,
        command_handler: self.class.to_s,
      ))
      user_id
    end

    private def seed_role(name : String, permissions : Array(CrystalBank::Permissions), scope_id : UUID, scopes : Array(UUID)) : UUID
      event = Roles::Creation::Events::Requested.new(
        actor_id: ACTOR_ID,
        command_handler: self.class.to_s,
        name: name,
        permissions: permissions,
        scope_id: scope_id,
        scopes: scopes,
      )
      @event_store.append(event)
      role_id = UUID.new(event.header.aggregate_id.to_s)
      @event_store.append(Roles::Creation::Events::Accepted.new(
        actor_id: ACTOR_ID,
        aggregate_id: role_id,
        aggregate_version: 2,
        command_handler: self.class.to_s,
      ))
      role_id
    end

    # The user aggregate has Onboarding::Requested (v1) + Accepted (v2) by the
    # time roles are assigned, so AssignRoles::Requested is v3 and Accepted v4.
    private def assign_role(user_id : UUID, role_id : UUID, scope_id : UUID)
      @event_store.append(Users::AssignRoles::Events::Requested.new(
        actor_id: ACTOR_ID,
        command_handler: self.class.to_s,
        aggregate_id: user_id,
        aggregate_version: 3,
        role_ids: [role_id],
        scope_id: scope_id,
      ))
      @event_store.append(Users::AssignRoles::Events::Accepted.new(
        actor_id: ACTOR_ID,
        aggregate_id: user_id,
        aggregate_version: 4,
        command_handler: self.class.to_s,
      ))
    end

    private def seed_api_key(name : String, user_id : UUID, scope_id : UUID) : Tuple(UUID, String)
      secret = UUID.random.to_s
      event = ApiKeys::Generation::Events::Requested.new(
        actor_id: ACTOR_ID,
        api_secret: Crypto::Bcrypt::Password.create(secret, cost: 10).to_s,
        command_handler: self.class.to_s,
        name: name,
        scope_id: scope_id,
        user_id: user_id,
      )
      @event_store.append(event)
      key_id = UUID.new(event.header.aggregate_id.to_s)
      @event_store.append(ApiKeys::Generation::Events::Accepted.new(
        actor_id: ACTOR_ID,
        aggregate_id: key_id,
        aggregate_version: 2,
        command_handler: self.class.to_s,
      ))
      {key_id, secret}
    end
  end
end
