require "../../../spec_helper"

describe CrystalBank::Domains::Customers::Queries::Customers do
  scope_id = UUID.new("00000000-0000-0000-0000-000000000001")

  it "returns the status field for a pending customer" do
    customer_id = UUID.v7

    event = Test::Customer::Events::Onboarding::Requested.new.create(aggr_id: customer_id)
    TEST_EVENT_STORE.append(event)
    Customers::Projections::Customers.new.apply(event)

    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::READ_customers_list,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    results = Customers::Queries::Customers.new.list(context, cursor: nil, limit: 100)
    customer = results.find { |c| c.id == customer_id }
    customer.should_not be_nil
    customer.not_nil!.status.should eq("pending")
  end

  it "returns the status field as active for an accepted customer" do
    customer_id = UUID.v7

    req = Test::Customer::Events::Onboarding::Requested.new.create(aggr_id: customer_id)
    acc = Test::Customer::Events::Onboarding::Accepted.new.create(aggr_id: customer_id)
    TEST_EVENT_STORE.append(req)
    TEST_EVENT_STORE.append(acc)
    Customers::Projections::Customers.new.apply(req)
    Customers::Projections::Customers.new.apply(acc)

    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::READ_customers_list,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    results = Customers::Queries::Customers.new.list(context, cursor: nil, limit: 100)
    customer = results.find { |c| c.id == customer_id }
    customer.should_not be_nil
    customer.not_nil!.status.should eq("active")
  end
end
