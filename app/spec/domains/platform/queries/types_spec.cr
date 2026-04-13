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

  it "includes all supported currency codes" do
    result = subject.list
    result.should contain("eur")
    result.should contain("usd")
    result.should contain("gbp")
    result.should contain("chf")
    result.should contain("jpy")
  end

  it "contains exactly the supported currencies" do
    result = subject.list
    result.size.should eq(CrystalBank::Types::Currencies::Supported.values.size)
  end

  it "does not include unsupported currencies" do
    result = subject.list
    result.should_not contain("aed")
    result.should_not contain("zar")
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

describe CrystalBank::Domains::Platform::Queries::PermissionGroups do
  subject = Platform::Queries::PermissionGroups.new

  it "returns a non-empty list" do
    subject.list.should_not be_empty
  end

  it "every group has a non-empty name and description" do
    subject.list.each do |group|
      group.name.should_not be_empty
      group.description.should_not be_empty
    end
  end

  it "every permission entry has a lowercase key and non-empty description" do
    subject.list.each do |group|
      group.permissions.each do |perm|
        perm.key.should eq(perm.key.downcase)
        perm.description.should_not be_empty
      end
    end
  end

  it "includes known groups" do
    names = subject.list.map(&.name)
    names.should contain("Accounts")
    names.should contain("Platform")
  end

  it "places read_accounts_list in the Accounts group" do
    accounts_group = subject.list.find { |g| g.name == "Accounts" }
    accounts_group.should_not be_nil
    accounts_group.not_nil!.permissions.map(&.key).should contain("read_accounts_list")
  end

  it "covers every Permissions value exactly once" do
    all_keys = subject.list.flat_map { |g| g.permissions.map(&.key) }
    all_keys.size.should eq(CrystalBank::Permissions.values.size)
    all_keys.uniq.size.should eq(all_keys.size)
  end
end
