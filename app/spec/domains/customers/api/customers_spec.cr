require "../../../spec_helper"

describe CrystalBank::Domains::Customers::Api::Customers do
  customer_id = UUID.v7
  available_scope_id = UUID.new("00000000-0000-0000-0000-000000000001")

  before_all do
    req = Test::Customer::Events::Onboarding::Requested.new.create(aggr_id: customer_id)
    acc = Test::Customer::Events::Onboarding::Accepted.new.create(aggr_id: customer_id)
    TEST_EVENT_STORE.append(req)
    TEST_EVENT_STORE.append(acc)
    Customers::Projections::Customers.new.apply(req)
    Customers::Projections::Customers.new.apply(acc)
  end

  describe "GET /customers - scope filtering" do
    it "returns the seeded customer when available_scopes matches" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_customers_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Customers::Queries::Customers.new.list(context, cursor: nil, limit: 100)
      results.map(&.id).should contain(customer_id)
    end

    it "returns no customers when available_scopes does not match" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_customers_list,
        scope: UUID.v7,
        available_scopes: [UUID.v7]
      )

      results = Customers::Queries::Customers.new.list(context, cursor: nil, limit: 100)
      results.map(&.id).should_not contain(customer_id)
    end

    it "returns no customers when cursor is past all records" do
      context = CrystalBank::Api::Context.new(
        user_id: UUID.v7,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::READ_customers_list,
        scope: available_scope_id,
        available_scopes: [available_scope_id]
      )

      results = Customers::Queries::Customers.new.list(context, cursor: UUID.new("ffffffff-ffff-ffff-ffff-ffffffffffff"), limit: 100)
      results.should be_empty
    end
  end
end
