require "../../../../spec_helper"

private def seed_collection_pending_approval(requestor_id : UUID) : UUID
  aggregate_id = UUID.v7
  TEST_EVENT_STORE.append(
    Approvals::Creation::Events::Requested.new(
      actor_id: requestor_id,
      aggregate_id: aggregate_id,
      command_handler: "test",
      scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
      source_aggregate_type: "Account",
      source_aggregate_id: UUID.v7,
      required_approvals: ["write_accounts_opening_compliance_approval"],
      comment: ""
    )
  )
  aggregate_id
end

describe CrystalBank::Domains::Approvals::Collection::Commands::Request do
  requestor_id = UUID.new("00000000-0000-0000-0000-000000000010")
  collector_id = UUID.new("00000000-0000-0000-0000-000000000020")
  scope_id     = UUID.new("00000000-0000-0000-0000-100000000001")

  r   = CrystalBank::Domains::Approvals::Api::Requests::CollectRequest.from_json("{}")
  ctx = CrystalBank::Api::Context.new(
    user_id: collector_id,
    roles: [] of UUID,
    required_permission: CrystalBank::Permissions::WRITE_approvals_collection_request,
    scope: scope_id,
    available_scopes: [scope_id]
  )

  describe "guard: already completed" do
    it "raises InvalidArgument" do
      aggregate_id = seed_collection_pending_approval(requestor_id)
      TEST_EVENT_STORE.append(
        Approvals::Collection::Events::Completed.new(
          actor_id: collector_id,
          aggregate_id: aggregate_id,
          aggregate_version: 2,
          command_handler: "test",
          comment: ""
        )
      )

      expect_raises(CrystalBank::Exception::InvalidArgument, "Approval process is already completed") do
        Approvals::Collection::Commands::Request.new.call(aggregate_id, r, ctx)
      end
    end
  end

  describe "guard: already rejected" do
    it "raises InvalidArgument" do
      aggregate_id = seed_collection_pending_approval(requestor_id)
      TEST_EVENT_STORE.append(
        Approvals::Rejection::Events::Rejected.new(
          actor_id: requestor_id,
          aggregate_id: aggregate_id,
          aggregate_version: 2,
          command_handler: "test",
          user_id: requestor_id,
          comment: ""
        )
      )

      expect_raises(CrystalBank::Exception::InvalidArgument, "Approval process is already rejected") do
        Approvals::Collection::Commands::Request.new.call(aggregate_id, r, ctx)
      end
    end
  end

  describe "guard: requestor cannot collect their own request" do
    it "raises InvalidArgument" do
      aggregate_id = seed_collection_pending_approval(requestor_id)

      requestor_ctx = CrystalBank::Api::Context.new(
        user_id: requestor_id,
        roles: [] of UUID,
        required_permission: CrystalBank::Permissions::WRITE_approvals_collection_request,
        scope: scope_id,
        available_scopes: [scope_id]
      )

      expect_raises(CrystalBank::Exception::InvalidArgument, "Requestor cannot approve their own request") do
        Approvals::Collection::Commands::Request.new.call(aggregate_id, r, requestor_ctx)
      end
    end
  end

  describe "guard: user without required permissions" do
    it "raises InvalidArgument" do
      aggregate_id = seed_collection_pending_approval(requestor_id)

      expect_raises(CrystalBank::Exception::InvalidArgument, "User does not have any required approval permission") do
        Approvals::Collection::Commands::Request.new.call(aggregate_id, r, ctx)  # ctx has no roles
      end
    end
  end
end
