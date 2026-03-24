require "../../../spec_helper"

describe CrystalBank::Domains::Approvals::Api::Approvals do
  # IDs chosen to avoid collisions with query spec seeds
  pending_id = UUID.v7
  completed_id = UUID.v7
  rejected_id = UUID.v7
  available_scope_id = UUID.new("00000000-0000-0000-0000-100000000001")

  before_all do
    projection = ::Approvals::Projections::Approvals.new

    requested_pending = Test::Approval::Events::Creation::Requested.new.create(aggr_id: pending_id)
    projection.apply(requested_pending)

    requested_completed = Test::Approval::Events::Creation::Requested.new.create(aggr_id: completed_id)
    projection.apply(requested_completed)

    completed_event = Test::Approval::Events::Collection::Completed.new.create(aggr_id: completed_id)
    projection.apply(completed_event)

    requested_rejected = Test::Approval::Events::Creation::Requested.new.create(aggr_id: rejected_id)
    projection.apply(requested_rejected)

    rejected_event = Test::Approval::Events::Rejection::Rejected.new.create(aggr_id: rejected_id)
    projection.apply(rejected_event)
  end

  describe "GET /approvals status enum → query mapping" do
    describe "status = nil (no filter)" do
      it "returns pending, completed, and rejected approvals" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100)
        ids = results.map(&.id)
        ids.should contain(pending_id)
        ids.should contain(completed_id)
        ids.should contain(rejected_id)
      end
    end

    describe "status = Status::Pending" do
      it "excludes completed and rejected approvals" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100, status: CrystalBank::Types::Approvals::Status::Pending)
        ids = results.map(&.id)
        ids.should contain(pending_id)
        ids.should_not contain(completed_id)
        ids.should_not contain(rejected_id)
      end
    end

    describe "status = Status::Completed" do
      it "returns only completed approvals" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100, status: CrystalBank::Types::Approvals::Status::Completed)
        ids = results.map(&.id)
        ids.should contain(completed_id)
        ids.should_not contain(pending_id)
        ids.should_not contain(rejected_id)
      end
    end

    describe "status = Status::Rejected" do
      it "returns only rejected approvals" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100, status: CrystalBank::Types::Approvals::Status::Rejected)
        ids = results.map(&.id)
        ids.should contain(rejected_id)
        ids.should_not contain(pending_id)
        ids.should_not contain(completed_id)
      end
    end

    describe "Respect scopes" do
      it "does not return anything for invalid scope" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [UUID.v7])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100)
        ids = results.map(&.id)
        ids.should eq([] of UUID)
      end
    end

    describe "Status enum parsing" do
      it "parses 'pending' case-insensitively" do
        CrystalBank::Types::Approvals::Status.parse("pending").should eq(CrystalBank::Types::Approvals::Status::Pending)
        CrystalBank::Types::Approvals::Status.parse("PENDING").should eq(CrystalBank::Types::Approvals::Status::Pending)
      end

      it "parses 'completed' case-insensitively" do
        CrystalBank::Types::Approvals::Status.parse("completed").should eq(CrystalBank::Types::Approvals::Status::Completed)
        CrystalBank::Types::Approvals::Status.parse("COMPLETED").should eq(CrystalBank::Types::Approvals::Status::Completed)
      end

      it "parses 'rejected' case-insensitively" do
        CrystalBank::Types::Approvals::Status.parse("rejected").should eq(CrystalBank::Types::Approvals::Status::Rejected)
        CrystalBank::Types::Approvals::Status.parse("REJECTED").should eq(CrystalBank::Types::Approvals::Status::Rejected)
      end

      it "raises on unknown status values" do
        expect_raises(ArgumentError) do
          CrystalBank::Types::Approvals::Status.parse("invalid_status")
        end
      end

      it "serialises to lowercase string" do
        CrystalBank::Types::Approvals::Status::Pending.to_s.should eq("pending")
        CrystalBank::Types::Approvals::Status::Completed.to_s.should eq("completed")
        CrystalBank::Types::Approvals::Status::Rejected.to_s.should eq("rejected")
      end
    end
  end
end
