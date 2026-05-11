require "../../../spec_helper"

describe CrystalBank::Domains::Approvals::Aggregates::Concerns::Creation do
  describe "#apply" do
    it "Properly populates the aggregate on approval creation" do
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000001")
      scope_id = UUID.new("00000000-0000-0000-0000-100000000001")
      source_aggregate_type = "Account"
      source_aggregate_id = UUID.new("00000000-0000-0000-0000-200000000001")
      required_approvals = [
        "write_accounts_opening_compliance_approval",
        "write_accounts_opening_board_approval",
      ]

      aggregate = Approvals::Aggregate.new(aggregate_id)

      # Creation request
      event = Approvals::Creation::Events::Requested.new(
        actor_id: UUID.new("00000000-0000-0000-0000-000000000000"),
        aggregate_id: aggregate_id,
        command_handler: "test",
        scope_id: scope_id,
        source_aggregate_type: source_aggregate_type,
        source_aggregate_id: source_aggregate_id,
        required_approvals: required_approvals,
        subject: nil
      )
      aggregate.apply(event)

      state = aggregate.state
      state.aggregate_id.should eq(aggregate_id)
      state.aggregate_version.should eq(1)
      state.scope_id.should eq(scope_id)
      state.source_aggregate_type.should eq(source_aggregate_type)
      state.source_aggregate_id.should eq(source_aggregate_id)
      state.required_approvals.should eq(required_approvals)
      state.completed.should eq(false)
      state.subject.should be_nil
    end

    it "stores the subject snapshot when one is provided" do
      aggregate_id = UUID.new("00000000-0000-0000-0000-000000000002")

      subject_snapshot = Approvals::ApprovalSubject.new(
        title: "SEPA Credit Transfer",
        summary: "100.00 EUR → DE89370400440532013000 (Acme GmbH)",
        fields: [Approvals::ApprovalSubject::Field.new("Amount", "100.00 EUR")]
      )

      aggregate = Approvals::Aggregate.new(aggregate_id)
      event = Approvals::Creation::Events::Requested.new(
        actor_id: UUID.new("00000000-0000-0000-0000-000000000000"),
        aggregate_id: aggregate_id,
        command_handler: "test",
        scope_id: UUID.new("00000000-0000-0000-0000-100000000001"),
        source_aggregate_type: "SepaCreditTransfer",
        source_aggregate_id: UUID.new("00000000-0000-0000-0000-200000000001"),
        required_approvals: ["write_payments_sepa_credit_transfers_approval"],
        subject: subject_snapshot
      )
      aggregate.apply(event)

      state = aggregate.state
      state.subject.should_not be_nil
      state.subject.not_nil!.title.should eq("SEPA Credit Transfer")
      state.subject.not_nil!.summary.should eq("100.00 EUR → DE89370400440532013000 (Acme GmbH)")
      state.subject.not_nil!.fields.size.should eq(1)
    end
  end
end
