require "../../../../spec_helper"

private def seed_rejection_pending_approval(requestor_id : UUID) : UUID
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

describe CrystalBank::Domains::Approvals::Rejection::Commands::Request do
  requestor_id  = UUID.new("00000000-0000-0000-0000-000000000010")
  other_user_id = UUID.new("00000000-0000-0000-0000-000000000020")
  scope_id      = UUID.new("00000000-0000-0000-0000-100000000001")

  r = CrystalBank::Domains::Approvals::Api::Requests::RejectRequest.from_json("{}")

  requestor_ctx = CrystalBank::Api::Context.new(
    user_id: requestor_id,
    roles: [] of UUID,
    required_permission: CrystalBank::Permissions::WRITE_approvals_rejection_request,
    scope: scope_id,
    available_scopes: [scope_id]
  )

  other_ctx = CrystalBank::Api::Context.new(
    user_id: other_user_id,
    roles: [] of UUID,
    required_permission: CrystalBank::Permissions::WRITE_approvals_rejection_request,
    scope: scope_id,
    available_scopes: [scope_id]
  )

  describe "guard: already completed" do
    it "raises InvalidArgument" do
      aggregate_id = seed_rejection_pending_approval(requestor_id)
      TEST_EVENT_STORE.append(
        Approvals::Collection::Events::Completed.new(
          actor_id: other_user_id,
          aggregate_id: aggregate_id,
          aggregate_version: 2,
          command_handler: "test",
          comment: ""
        )
      )

      expect_raises(CrystalBank::Exception::InvalidArgument, "Approval process is already completed") do
        Approvals::Rejection::Commands::Request.new.call(aggregate_id, r, requestor_ctx)
      end
    end
  end

  describe "guard: already rejected" do
    it "raises InvalidArgument" do
      aggregate_id = seed_rejection_pending_approval(requestor_id)
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
        Approvals::Rejection::Commands::Request.new.call(aggregate_id, r, requestor_ctx)
      end
    end
  end

  describe "guard: non-requestor without required permissions" do
    it "raises InvalidArgument" do
      aggregate_id = seed_rejection_pending_approval(requestor_id)

      expect_raises(CrystalBank::Exception::InvalidArgument, "User does not have permission to reject this approval") do
        Approvals::Rejection::Commands::Request.new.call(aggregate_id, r, other_ctx)  # other_ctx has no roles
      end
    end
  end

  describe "happy path: requestor can reject their own request" do
    it "appends the Rejected event without requiring any roles" do
      aggregate_id = seed_rejection_pending_approval(requestor_id)

      # Should not raise — requestor bypasses the permission check
      Approvals::Rejection::Commands::Request.new.call(aggregate_id, r, requestor_ctx)

      aggregate = Approvals::Aggregate.new(aggregate_id)
      aggregate.hydrate
      aggregate.state.rejected.should be_true
    end
  end
end
