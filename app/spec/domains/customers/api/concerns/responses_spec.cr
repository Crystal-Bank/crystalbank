require "../../../../spec_helper"

describe CrystalBank::Domains::Customers::Api::Responses do
  describe "Customer" do
    it "serializes all fields including status" do
      id = UUID.v7
      scope_id = UUID.v7

      customer = CrystalBank::Domains::Customers::Api::Responses::Customer.new(
        id,
        scope_id,
        "Peter Pan",
        CrystalBank::Types::Customers::Type::Individual,
        "pending"
      )

      json = customer.to_json
      parsed = JSON.parse(json)

      parsed["id"].as_s.should eq(id.to_s)
      parsed["scope_id"].as_s.should eq(scope_id.to_s)
      parsed["name"].as_s.should eq("Peter Pan")
      parsed["type"].as_s.should eq("individual")
      parsed["status"].as_s.should eq("pending")
    end
  end
end
