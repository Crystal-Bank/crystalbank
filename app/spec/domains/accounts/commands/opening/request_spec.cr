require "../../../../spec_helper"

describe CrystalBank::Domains::Accounts::Opening::Commands::Request do
  scope_id = UUID.new("00000000-0000-0000-0000-000000000001")

  def make_context(scope_id : UUID) : CrystalBank::Api::Context
    CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_accounts_opening_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )
  end

  def seed_customer(scope_id : UUID) : UUID
    customer_id = UUID.v7
    requested = Customers::Onboarding::Events::Requested.new(
      actor_id: UUID.v7,
      aggregate_id: customer_id,
      name: "Test Customer",
      scope_id: scope_id,
      type: CrystalBank::Types::Customers::Type::Individual,
      command_handler: "test",
      comment: "test"
    )
    accepted = Test::Customer::Events::Onboarding::Accepted.new.create(aggr_id: customer_id)
    TEST_EVENT_STORE.append(requested)
    TEST_EVENT_STORE.append(accepted)
    Customers::Projections::Customers.new.apply(accepted)
    customer_id
  end

  def make_request(customer_ids : Array(UUID)) : Accounts::Api::Requests::OpeningRequest
    Accounts::Api::Requests::OpeningRequest.from_json({
      "name"         => "Test Account",
      "currencies"   => ["eur"],
      "customer_ids" => customer_ids.map(&.to_s),
      "type"         => "checking",
    }.to_json)
  end

  it "raises when customer_ids is empty" do
    context = make_context(scope_id)
    request = make_request([] of UUID)

    expect_raises(CrystalBank::Exception::InvalidArgument, /At least one customer ID is required/) do
      Accounts::Opening::Commands::Request.new.call(request, context)
    end
  end

  it "raises when a customer ID does not exist in the projection" do
    context = make_context(scope_id)
    request = make_request([UUID.v7])

    expect_raises(CrystalBank::Exception::InvalidArgument, /does not exist/) do
      Accounts::Opening::Commands::Request.new.call(request, context)
    end
  end

  it "raises when a customer belongs to a different scope" do
    other_scope = UUID.v7
    customer_id = seed_customer(other_scope)

    context = make_context(scope_id)
    request = make_request([customer_id])

    expect_raises(CrystalBank::Exception::InvalidArgument, /does not exist/) do
      Accounts::Opening::Commands::Request.new.call(request, context)
    end
  end

  it "creates an account opening request when all customer IDs are valid and in scope" do
    customer_id = seed_customer(scope_id)

    context = make_context(scope_id)
    request = make_request([customer_id])

    result = Accounts::Opening::Commands::Request.new.call(request, context)
    result.should be_a(UUID)
  end
end
