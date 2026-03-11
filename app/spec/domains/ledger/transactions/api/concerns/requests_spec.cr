require "../../../../../spec_helper"

describe CrystalBank::Domains::Ledger::Transactions::Api::Requests do
  describe "TransactionRequest" do
    it "parses a valid request body" do
      debit_account_id = UUID.v7
      credit_account_id = UUID.v7

      json = {
        "currency"                => "EUR",
        "remittance_information"  => "Payment ref 001",
        "entries"                 => [
          {"account_id" => debit_account_id.to_s, "direction" => "DEBIT", "amount" => 5000, "entry_type" => "PRINCIPAL"},
          {"account_id" => credit_account_id.to_s, "direction" => "CREDIT", "amount" => 5000, "entry_type" => "PRINCIPAL"},
        ],
      }.to_json

      request = Ledger::Transactions::Api::Requests::TransactionRequest.from_json(json)

      request.currency.to_s.should eq("EUR")
      request.remittance_information.should eq("Payment ref 001")
      request.entries.size.should eq(2)
      request.entries[0].direction.to_s.should eq("DEBIT")
      request.entries[1].direction.to_s.should eq("CREDIT")
    end
  end

  describe "EntryRequest" do
    it "parses a valid debit entry" do
      account_id = UUID.v7

      json = {
        "account_id"  => account_id.to_s,
        "direction"   => "DEBIT",
        "amount"      => 100,
        "entry_type"  => "PRINCIPAL",
      }.to_json

      entry = Ledger::Transactions::Api::Requests::EntryRequest.from_json(json)

      entry.account_id.should eq(account_id)
      entry.direction.to_s.should eq("DEBIT")
      entry.amount.should eq(100_i64)
      entry.entry_type.to_s.should eq("PRINCIPAL")
    end
  end
end
