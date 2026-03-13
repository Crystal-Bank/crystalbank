require "../../../spec_helper"

describe CrystalBank::Domains::Approvals::Api::Approvals do
  # IDs chosen to avoid collisions with query spec seeds
  pending_id = UUID.new("00000000-0000-0000-0000-bbb000000010")
  completed_id = UUID.new("00000000-0000-0000-0000-bbb000000020")

  before_all do
    projection = ::Approvals::Projections::Approvals.new

    requested_pending = Test::Approval::Events::Creation::Requested.new.create(aggr_id: pending_id)
    projection.apply(requested_pending)

    requested_completed = Test::Approval::Events::Creation::Requested.new.create(aggr_id: completed_id)
    projection.apply(requested_completed)

    completed_event = Test::Approval::Events::Collection::Completed.new.create(aggr_id: completed_id)
    projection.apply(completed_event)
  end

  describe "GET /approvals status enum → query mapping" do
    describe "status = nil (no filter)" do
      it "returns both pending and completed approvals" do
        results = ::Approvals::Queries::Approvals.new.list(cursor: nil, limit: 100)
        ids = results.map(&.id)
        ids.should contain(pending_id)
        ids.should contain(completed_id)
      end
    end

    describe "status = Status::Pending" do
      it "maps to completed: false and excludes completed approvals" do
        status = CrystalBank::Types::Approvals::Status::Pending
        completed = status == CrystalBank::Types::Approvals::Status::Completed ? true : false

        results = ::Approvals::Queries::Approvals.new.list(cursor: nil, limit: 100, completed: completed)
        ids = results.map(&.id)
        ids.should contain(pending_id)
        ids.should_not contain(completed_id)
      end
    end

    describe "status = Status::Completed" do
      it "maps to completed: true and excludes pending approvals" do
        status = CrystalBank::Types::Approvals::Status::Completed
        completed = status == CrystalBank::Types::Approvals::Status::Completed ? true : false

        results = ::Approvals::Queries::Approvals.new.list(cursor: nil, limit: 100, completed: completed)
        ids = results.map(&.id)
        ids.should contain(completed_id)
        ids.should_not contain(pending_id)
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

      it "raises on unknown status values" do
        expect_raises(ArgumentError) do
          CrystalBank::Types::Approvals::Status.parse("invalid_status")
        end
      end

      it "serialises to lowercase string" do
        CrystalBank::Types::Approvals::Status::Pending.to_s.should eq("pending")
        CrystalBank::Types::Approvals::Status::Completed.to_s.should eq("completed")
      end
    end
  end
end
