require "../../spec_helper"

describe CrystalBank::Domains::Approvals::ApprovalSubject do
  describe "JSON serialization" do
    it "serializes all fields correctly" do
      subject = Approvals::ApprovalSubject.new(
        title: "SEPA Credit Transfer",
        summary: "250.00 EUR → DE89370400440532013000 (Acme GmbH)",
        fields: [
          Approvals::ApprovalSubject::Field.new("Amount", "250.00 EUR"),
          Approvals::ApprovalSubject::Field.new("Creditor Name", "Acme GmbH"),
        ]
      )

      json = JSON.parse(subject.to_json)
      json["title"].as_s.should eq("SEPA Credit Transfer")
      json["summary"].as_s.should eq("250.00 EUR → DE89370400440532013000 (Acme GmbH)")
      json["fields"].as_a.size.should eq(2)
      json["fields"][0]["label"].as_s.should eq("Amount")
      json["fields"][0]["value"].as_s.should eq("250.00 EUR")
    end

    it "round-trips through JSON" do
      original = Approvals::ApprovalSubject.new(
        title: "Account Block",
        summary: "COMPLIANCE_BLOCK on \"Acme Account\"",
        fields: [
          Approvals::ApprovalSubject::Field.new("Account", "Acme Account"),
          Approvals::ApprovalSubject::Field.new("Block Type", "COMPLIANCE_BLOCK"),
          Approvals::ApprovalSubject::Field.new("Reason", "AML review"),
        ]
      )

      rehydrated = Approvals::ApprovalSubject.from_json(original.to_json)
      rehydrated.title.should eq(original.title)
      rehydrated.summary.should eq(original.summary)
      rehydrated.fields.size.should eq(3)
      rehydrated.fields.last.label.should eq("Reason")
      rehydrated.fields.last.value.should eq("AML review")
    end
  end
end
