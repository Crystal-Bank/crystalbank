require "../../../../../spec_helper"

describe CrystalBank::Domains::Ledger::Transactions::Api::Responses do
  describe "TransactionResponse" do
    it "serializes to json with an id field" do
      uuid = UUID.v7
      response = Ledger::Transactions::Api::Responses::TransactionResponse.new(uuid)

      json = JSON.parse(response.to_json)
      json["id"].as_s.should eq(uuid.to_s)
    end
  end
end
