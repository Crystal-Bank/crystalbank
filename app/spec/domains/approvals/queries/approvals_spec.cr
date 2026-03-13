require "../../../spec_helper"

describe CrystalBank::Domains::Approvals::Queries::Approvals do
  pending_id = UUID.v7
  completed_id = UUID.v7
  available_scope_id = UUID.new("00000000-0000-0000-0000-100000000001")

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
        # Build a context as the API controller would after a successful authorized? call
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100)
        ids = results.map(&.id)
        ids.should contain(pending_id)
        ids.should contain(completed_id)
      end
    end

    describe "with completed: false (pending)" do
      it "returns only pending approvals" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100, completed: false)
        ids = results.map(&.id)
        ids.should contain(pending_id)
        ids.should_not contain(completed_id)
      end

      it "all returned approvals have completed == false" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100, completed: false)
        results.each { |a| a.completed.should be_false }
      end
    end

    describe "with completed: true (completed)" do
      it "returns only completed approvals" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100, completed: true)
        ids = results.map(&.id)
        ids.should contain(completed_id)
        ids.should_not contain(pending_id)
      end

      it "all returned approvals have completed == true" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100, completed: true)
        results.each { |a| a.completed.should be_true }
      end
    end

    describe "pagination cursor" do
      it "respects cursor when combined with status filter" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        # cursor set to an ID after completed_id means neither seeded row is returned
        beyond_cursor = completed_id
        results = ::Approvals::Queries::Approvals.new.list(context, cursor: beyond_cursor, limit: 100, completed: false)
        ids = results.map(&.id)
        ids.should_not contain(pending_id)
      end

      it "returns approvals starting from cursor UUID (inclusive)" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: pending_id, limit: 100, completed: false)
        ids = results.map(&.id)
        ids.should contain(pending_id)
      end
    end
  end
end
