require "../../../spec_helper"

describe CrystalBank::Domains::Platform::Queries::Permissions do
  subject = Platform::Queries::Permissions.new

  it "returns a non-empty list" do
    subject.list.should_not be_empty
  end

  it "returns lowercase strings" do
    subject.list.each { |v| v.should eq(v.downcase) }
  end

  it "returns a sorted list" do
    result = subject.list
    result.should eq(result.sort)
  end

  it "includes known permissions" do
    result = subject.list
    result.should contain("read_accounts_list")
    result.should contain("write_accounts_opening_request")
    result.should contain("read_platform_types")
  end

  it "contains all defined permissions" do
    result = subject.list
    result.size.should eq(CrystalBank::Permissions.values.size)
  end
end

describe CrystalBank::Domains::Platform::Queries::AccountTypes do
  subject = Platform::Queries::AccountTypes.new

  it "returns a non-empty list" do
    subject.list.should_not be_empty
  end

  it "returns lowercase strings" do
    subject.list.each { |v| v.should eq(v.downcase) }
  end

  it "returns a sorted list" do
    result = subject.list
    result.should eq(result.sort)
  end

  it "includes known account types" do
    result = subject.list
    result.should contain("checking")
    result.should contain("savings")
    result.should contain("settlement")
  end

  it "contains all defined account types" do
    result = subject.list
    result.size.should eq(CrystalBank::Types::Accounts::Type.values.size)
  end
end

describe CrystalBank::Domains::Platform::Queries::Currencies do
  subject = Platform::Queries::Currencies.new

  it "returns a non-empty list" do
    subject.list.should_not be_empty
  end

  it "returns lowercase strings" do
    subject.list.each { |v| v.should eq(v.downcase) }
  end

  it "returns a sorted list" do
    result = subject.list
    result.should eq(result.sort)
  end

  it "includes known ISO 4217 currency codes" do
    result = subject.list
    result.should contain("eur")
    result.should contain("usd")
    result.should contain("gbp")
    result.should contain("chf")
  end

  it "contains all defined available currencies" do
    result = subject.list
    result.size.should eq(CrystalBank::Types::Currencies::Available.values.size)
  end
end

describe CrystalBank::Domains::Platform::Queries::CustomerTypes do
  subject = Platform::Queries::CustomerTypes.new

  it "returns a non-empty list" do
    subject.list.should_not be_empty
  end

  it "returns lowercase strings" do
    subject.list.each { |v| v.should eq(v.downcase) }
  end

  it "returns a sorted list" do
    result = subject.list
    result.should eq(result.sort)
  end

  it "includes all defined customer types" do
    result = subject.list
    result.should contain("business")
    result.should contain("individual")
    result.size.should eq(CrystalBank::Types::Customers::Type.values.size)
  end
end

describe CrystalBank::Domains::Platform::Queries::LedgerEntryTypes do
  subject = Platform::Queries::LedgerEntryTypes.new

  it "returns a non-empty list" do
    subject.list.should_not be_empty
  end

  it "returns lowercase strings" do
    subject.list.each { |v| v.should eq(v.downcase) }
  end

  it "returns a sorted list" do
    result = subject.list
    result.should eq(result.sort)
  end

  it "includes known entry types" do
    result = subject.list
    result.should contain("principal")
    result.should contain("adjustment")
    result.should contain("reversal")
    result.should contain("sepa_credit_transfer")
  end

  it "contains all defined ledger entry types" do
    result = subject.list
    result.size.should eq(CrystalBank::Types::LedgerTransactions::EntryType.values.size)
  end
end
