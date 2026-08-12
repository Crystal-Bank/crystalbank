require "../../../../../spec_helper"

describe CrystalBank::Domains::Ledger::Transactions::Api::Responses do
  describe "TransactionResponse" do
    it "serializes to json with id and approval_id fields" do
      uuid = UUID.v7
      approval_id = UUID.v7
      response = Ledger::Transactions::Api::Responses::TransactionResponse.new(uuid, approval_id)

      json = JSON.parse(response.to_json)
      json["id"].as_s.should eq(uuid.to_s)
      json["approval_id"].as_s.should eq(approval_id.to_s)
    end
  end
end
