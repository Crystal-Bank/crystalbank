require "../../../spec_helper"

describe CrystalBank::Domains::Approvals::Queries::Approvals do
  pending_id = UUID.new("00000000-0000-0000-0000-aaa000000010")
  completed_id = UUID.new("00000000-0000-0000-0000-aaa000000020")

  # Seed two approvals — one pending, one completed — before running cases
  before_all do
    projection = ::Approvals::Projections::Approvals.new

    requested_pending = Test::Approval::Events::Creation::Requested.new.create(aggr_id: pending_id)
    projection.apply(requested_pending)

    requested_completed = Test::Approval::Events::Creation::Requested.new.create(aggr_id: completed_id)
    projection.apply(requested_completed)

    completed_event = Test::Approval::Events::Collection::Completed.new.create(aggr_id: completed_id)
    projection.apply(completed_event)
  end

  describe "#list" do
    describe "without status filter" do
      it "returns both pending and completed approvals" do
        results = ::Approvals::Queries::Approvals.new.list(cursor: nil, limit: 100)
        ids = results.map(&.id)
        ids.should contain(pending_id)
        ids.should contain(completed_id)
      end
    end

    describe "with completed: false (pending)" do
      it "returns only pending approvals" do
        results = ::Approvals::Queries::Approvals.new.list(cursor: nil, limit: 100, completed: false)
        ids = results.map(&.id)
        ids.should contain(pending_id)
        ids.should_not contain(completed_id)
      end

      it "all returned approvals have completed == false" do
        results = ::Approvals::Queries::Approvals.new.list(cursor: nil, limit: 100, completed: false)
        results.each { |a| a.completed.should be_false }
      end
    end

    describe "with completed: true (completed)" do
      it "returns only completed approvals" do
        results = ::Approvals::Queries::Approvals.new.list(cursor: nil, limit: 100, completed: true)
        ids = results.map(&.id)
        ids.should contain(completed_id)
        ids.should_not contain(pending_id)
      end

      it "all returned approvals have completed == true" do
        results = ::Approvals::Queries::Approvals.new.list(cursor: nil, limit: 100, completed: true)
        results.each { |a| a.completed.should be_true }
      end
    end

    describe "pagination cursor" do
      it "respects cursor when combined with status filter" do
        # cursor set to an ID after completed_id means neither seeded row is returned
        beyond_cursor = UUID.new("00000000-0000-0000-0000-fff000000000")
        results = ::Approvals::Queries::Approvals.new.list(cursor: beyond_cursor, limit: 100, completed: false)
        ids = results.map(&.id)
        ids.should_not contain(pending_id)
      end

      it "returns approvals starting from cursor UUID (inclusive)" do
        results = ::Approvals::Queries::Approvals.new.list(cursor: pending_id, limit: 100, completed: false)
        ids = results.map(&.id)
        ids.should contain(pending_id)
      end
    end
  end
end
