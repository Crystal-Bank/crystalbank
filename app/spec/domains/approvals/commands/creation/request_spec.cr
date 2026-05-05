require "../../../../spec_helper"

describe CrystalBank::Domains::Approvals::Creation::Commands::Request do
  scope_id = UUID.new("00000000-0000-0000-0000-100000000001")
  actor_id = UUID.new("00000000-0000-0000-0000-000000000001")

  describe "guard: empty required_approvals" do
    it "raises InvalidArgument" do
      expect_raises(CrystalBank::Exception::InvalidArgument, "Required approvals cannot be empty") do
        Approvals::Creation::Commands::Request.new.call(
          source_aggregate_type: "Account",
          source_aggregate_id: UUID.v7,
          scope_id: scope_id,
          required_approvals: [] of String,
          actor_id: actor_id,
        )
      end
    end
  end

  describe "without subject" do
    it "appends a Requested event and returns the approval aggregate ID" do
      approval_id = Approvals::Creation::Commands::Request.new.call(
        source_aggregate_type: "Account",
        source_aggregate_id: UUID.v7,
        scope_id: scope_id,
        required_approvals: ["write_accounts_opening_compliance_approval"],
        actor_id: actor_id,
      )

      approval_id.should be_a(UUID)

      aggregate = Approvals::Aggregate.new(approval_id)
      aggregate.hydrate
      aggregate.state.source_aggregate_type.should eq("Account")
      aggregate.state.required_approvals.should eq(["write_accounts_opening_compliance_approval"])
      aggregate.state.subject.should be_nil
    end
  end

  describe "with subject" do
    it "stores the subject snapshot on the aggregate" do
      subject_snapshot = Approvals::ApprovalSubject.new(
        title: "Account Block",
        summary: "COMPLIANCE_BLOCK on \"Test Account\"",
        fields: [
          Approvals::ApprovalSubject::Field.new("Account", "Test Account"),
          Approvals::ApprovalSubject::Field.new("Block Type", "COMPLIANCE_BLOCK"),
        ]
      )

      approval_id = Approvals::Creation::Commands::Request.new.call(
        source_aggregate_type: "AccountBlock",
        source_aggregate_id: UUID.v7,
        scope_id: scope_id,
        required_approvals: ["write_accounts_blocking_approval"],
        actor_id: actor_id,
        subject: subject_snapshot,
      )

      aggregate = Approvals::Aggregate.new(approval_id)
      aggregate.hydrate
      aggregate.state.subject.should_not be_nil
      aggregate.state.subject.not_nil!.title.should eq("Account Block")
      aggregate.state.subject.not_nil!.fields.size.should eq(2)
    end
  end
end
