require "../../../../spec_helper"

describe CrystalBank::Domains::Roles::Creation::Commands::Request do
  scope_id = UUID.new("00000000-0000-0000-0000-100000000001")

  def make_context(scope = UUID.new("00000000-0000-0000-0000-100000000001"))
    CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_roles_creation_request,
      scope: scope,
      available_scopes: [scope]
    )
  end

  def make_request(scopes : Array(UUID) = [] of UUID)
    Roles::Api::Requests::CreationRequest.from_json({
      name:        "Test Role",
      permissions: ["write_roles_creation_request"],
      scopes:      scopes.map(&.to_s),
    }.to_json)
  end

  it "appends a Requested event and returns the aggregate ID" do
    role_id = Roles::Creation::Commands::Request.new.call(make_request, make_context)

    role_id.should be_a(UUID)

    aggregate = Roles::Aggregate.new(role_id)
    aggregate.hydrate

    aggregate.state.name.should eq("Test Role")
    aggregate.state.scope_id.should eq(scope_id)
    aggregate.state.aggregate_version.should eq(1)
  end

  it "raises when scope is missing from context" do
    expect_raises(CrystalBank::Exception::InvalidArgument, /Invalid scope/) do
      Roles::Creation::Commands::Request.new.call(make_request, make_context(scope: nil))
    end
  end

  it "accepts valid active scope IDs" do
    active_scope_id = UUID.v7
    scope_event = Test::Scope::Events::Creation::Requested.new.create(aggr_id: active_scope_id)
    accepted_event = Test::Scope::Events::Creation::Accepted.new.create(aggr_id: active_scope_id)
    TEST_EVENT_STORE.append(scope_event)
    TEST_EVENT_STORE.append(accepted_event)
    Scopes::Projections::Scopes.new.apply(scope_event)
    Scopes::Projections::Scopes.new.apply(accepted_event)

    role_id = Roles::Creation::Commands::Request.new.call(make_request(scopes: [active_scope_id]), make_context)
    role_id.should be_a(UUID)
  end

  it "raises when a provided scope ID does not exist" do
    nonexistent_id = UUID.v7

    expect_raises(CrystalBank::Exception::InvalidArgument, /Invalid or inactive scopes/) do
      Roles::Creation::Commands::Request.new.call(make_request(scopes: [nonexistent_id]), make_context)
    end
  end

  it "raises when a provided scope ID exists but is pending (not yet accepted)" do
    pending_scope_id = UUID.v7
    scope_event = Test::Scope::Events::Creation::Requested.new.create(aggr_id: pending_scope_id)
    TEST_EVENT_STORE.append(scope_event)
    Scopes::Projections::Scopes.new.apply(scope_event)

    expect_raises(CrystalBank::Exception::InvalidArgument, /Invalid or inactive scopes/) do
      Roles::Creation::Commands::Request.new.call(make_request(scopes: [pending_scope_id]), make_context)
    end
  end
end
