require "../../../../../spec_helper"

describe CrystalBank::Domains::Ledger::Transactions::Api::Requests do
  describe "TransactionRequest" do
    it "parses a valid request body" do
      debit_account_id = UUID.v7
      credit_account_id = UUID.v7

      json = {
        "currency"               => "EUR",
        "remittance_information" => "Payment ref 001",
        "posting_date"           => "2026-03-11",
        "value_date"             => "2026-03-12",
        "entries"                => [
          {"account_id" => debit_account_id.to_s, "direction" => "debit", "amount" => 5000, "entry_type" => "principal"},
          {"account_id" => credit_account_id.to_s, "direction" => "credit", "amount" => 5000, "entry_type" => "principal"},
        ],
      }.to_json

      request = Ledger::Transactions::Api::Requests::TransactionRequest.from_json(json)

      request.currency.should eq(CrystalBank::Types::Currencies::Supported::EUR)
      request.remittance_information.should eq("Payment ref 001")
      request.entries.size.should eq(2)
      request.entries[0].direction.should eq(CrystalBank::Types::LedgerTransactions::Direction::DEBIT)
      request.entries[1].direction.should eq(CrystalBank::Types::LedgerTransactions::Direction::CREDIT)
    end
  end

  describe "EntryRequest" do
    it "parses a valid debit entry" do
      account_id = UUID.v7

      json = {
        "account_id" => account_id.to_s,
        "direction"  => "debit",
        "amount"     => 100,
        "entry_type" => "principal",
      }.to_json

      entry = Ledger::Transactions::Api::Requests::EntryRequest.from_json(json)

      entry.account_id.should eq(account_id)
      entry.direction.should eq(CrystalBank::Types::LedgerTransactions::Direction::DEBIT)
      entry.amount.should eq(100_i64)
      entry.entry_type.should eq(CrystalBank::Types::LedgerTransactions::EntryType::PRINCIPAL)
    end
  end
end
