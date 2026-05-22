require "../../../../spec_helper"

describe CrystalBank::Domains::Accounts::VirtualAccount::Projections::VirtualAccounts do
  projection = Accounts::VirtualAccount::Projections::VirtualAccounts.new

  it "inserts a row with status pending_activation on Requested event" do
    uuid = UUID.v7
    event = Test::VirtualAccount::Events::Opening::Requested.new.create(aggr_id: uuid)
    TEST_EVENT_STORE.append(event)
    projection.apply(event)

    count = TEST_PROJECTION_DB.scalar(
      %(SELECT count(*) FROM "projections"."virtual_accounts" WHERE uuid = $1 AND status = 'pending_activation'),
      uuid
    )
    count.should eq(1)
  end

  it "updates status to active on Accepted event" do
    uuid = UUID.v7
    req = Test::VirtualAccount::Events::Opening::Requested.new.create(aggr_id: uuid)
    acc = Test::VirtualAccount::Events::Opening::Accepted.new.create(aggr_id: uuid)
    TEST_EVENT_STORE.append(req)
    TEST_EVENT_STORE.append(acc)

    projection.apply(req)
    projection.apply(acc)

    status = TEST_PROJECTION_DB.scalar(
      %(SELECT status FROM "projections"."virtual_accounts" WHERE uuid = $1),
      uuid
    )
    status.should eq("active")
  end

  it "stores parent_account_id from the Requested event" do
    uuid = UUID.v7
    parent_id = UUID.new("00000000-0000-0000-0000-000000000001")
    event = Test::VirtualAccount::Events::Opening::Requested.new.create(aggr_id: uuid, parent_account_id: parent_id)
    TEST_EVENT_STORE.append(event)
    projection.apply(event)

    stored_parent_id = TEST_PROJECTION_DB.scalar(
      %(SELECT parent_account_id FROM "projections"."virtual_accounts" WHERE uuid = $1),
      uuid
    )
    stored_parent_id.should eq(parent_id)
  end
end
