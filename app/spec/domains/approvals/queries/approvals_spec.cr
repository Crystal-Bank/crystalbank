require "../../../spec_helper"

describe CrystalBank::Domains::Approvals::Queries::Approvals do
  pending_id = UUID.v7
  completed_id = UUID.v7
  rejected_id = UUID.v7
  subject_id = UUID.v7
  available_scope_id = UUID.new("00000000-0000-0000-0000-100000000001")

  # Seed three approvals — pending, completed, rejected — and one with a subject before running cases
  before_all do
    projection = ::Approvals::Projections::Approvals.new

    requested_pending = Test::Approval::Events::Creation::Requested.new.create(aggr_id: pending_id)
    projection.apply(requested_pending)

    subject_snapshot = Approvals::ApprovalSubject.new(
      title: "SEPA Credit Transfer",
      summary: "100.00 EUR → DE89370400440532013000 (Acme GmbH)",
      fields: [Approvals::ApprovalSubject::Field.new("Amount", "100.00 EUR")]
    )
    requested_with_subject = Approvals::Creation::Events::Requested.new(
      actor_id: UUID.new("00000000-0000-0000-0000-000000000000"),
      aggregate_id: subject_id,
      command_handler: "test",
      scope_id: available_scope_id,
      source_aggregate_type: "SepaCreditTransfer",
      source_aggregate_id: UUID.new("00000000-0000-0000-0000-200000000001"),
      required_approvals: ["write_payments_sepa_credit_transfers_approval"],
      subject: subject_snapshot
    )
    projection.apply(requested_with_subject)

    requested_completed = Test::Approval::Events::Creation::Requested.new.create(aggr_id: completed_id)
    projection.apply(requested_completed)

    completed_event = Test::Approval::Events::Collection::Completed.new.create(aggr_id: completed_id)
    projection.apply(completed_event)

    requested_rejected = Test::Approval::Events::Creation::Requested.new.create(aggr_id: rejected_id)
    projection.apply(requested_rejected)

    rejected_event = Test::Approval::Events::Rejection::Rejected.new.create(aggr_id: rejected_id)
    projection.apply(rejected_event)
  end

  describe "#list" do
    describe "without status filter" do
      it "returns pending, completed, and rejected approvals" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100)
        ids = results.map(&.id)
        ids.should contain(pending_id)
        ids.should contain(completed_id)
        ids.should contain(rejected_id)
      end
    end

    describe "with status: Pending" do
      it "returns only pending approvals" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100, status: CrystalBank::Types::Approvals::Status::Pending)
        ids = results.map(&.id)
        ids.should contain(pending_id)
        ids.should_not contain(completed_id)
        ids.should_not contain(rejected_id)
      end

      it "all returned approvals have completed == false and rejected == false" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100, status: CrystalBank::Types::Approvals::Status::Pending)
        results.each do |a|
          a.completed.should be_false
          a.rejected.should be_false
        end
      end
    end

    describe "with status: Completed" do
      it "returns only completed approvals" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100, status: CrystalBank::Types::Approvals::Status::Completed)
        ids = results.map(&.id)
        ids.should contain(completed_id)
        ids.should_not contain(pending_id)
        ids.should_not contain(rejected_id)
      end

      it "all returned approvals have completed == true" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100, status: CrystalBank::Types::Approvals::Status::Completed)
        results.each { |a| a.completed.should be_true }
      end
    end

    describe "with status: Rejected" do
      it "returns only rejected approvals" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100, status: CrystalBank::Types::Approvals::Status::Rejected)
        ids = results.map(&.id)
        ids.should contain(rejected_id)
        ids.should_not contain(pending_id)
        ids.should_not contain(completed_id)
      end

      it "all returned approvals have rejected == true" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: nil, limit: 100, status: CrystalBank::Types::Approvals::Status::Rejected)
        results.each { |a| a.rejected.should be_true }
      end
    end

    describe "pagination cursor" do
      it "respects cursor when combined with status filter" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        beyond_cursor = UUID.v7
        results = ::Approvals::Queries::Approvals.new.list(context, cursor: beyond_cursor, limit: 100, status: CrystalBank::Types::Approvals::Status::Pending)
        ids = results.map(&.id)
        ids.should_not contain(pending_id)
      end

      it "returns approvals starting from cursor UUID (inclusive)" do
        context = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])

        results = ::Approvals::Queries::Approvals.new.list(context, cursor: pending_id, limit: 100, status: CrystalBank::Types::Approvals::Status::Pending)
        ids = results.map(&.id)
        ids.should contain(pending_id)
      end
    end
  end

  describe "subject JSONB round-trip" do
    it "persists and retrieves the subject snapshot via find_by_source" do
      approval = ::Approvals::Queries::Approvals.new.find_by_source("SepaCreditTransfer", UUID.new("00000000-0000-0000-0000-200000000001"))
      approval.should_not be_nil

      subject = approval.not_nil!.subject
      subject.should_not be_nil
      subject.not_nil!.title.should eq("SEPA Credit Transfer")
      subject.not_nil!.summary.should contain("100.00 EUR")
      subject.not_nil!.fields.size.should eq(1)
      subject.not_nil!.fields.first.label.should eq("Amount")
      subject.not_nil!.fields.first.value.should eq("100.00 EUR")
    end

    it "returns nil subject for approvals created without one" do
      ctx = CrystalBank::Api::Context.new(user_id: UUID.v7, roles: [] of UUID, required_permission: CrystalBank::Permissions::READ_approvals_list, scope: UUID.v7, available_scopes: [available_scope_id])
      results = ::Approvals::Queries::Approvals.new.list(ctx, cursor: pending_id, limit: 1)
      approval = results.find { |a| a.id == pending_id }
      approval.should_not be_nil
      approval.not_nil!.subject.should be_nil
    end
  end
end
