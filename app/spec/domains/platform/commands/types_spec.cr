require "../../../spec_helper"

private def make_types_context : CrystalBank::Api::Context
  CrystalBank::Api::Context.new(
    user_id: UUID.v7,
    roles: [] of UUID,
    required_permission: CrystalBank::Permissions::READ_platform_types,
    scope: nil,
    available_scopes: [] of UUID
  )
end

describe Platform::Types::Commands::FetchPermissions do
  context = make_types_context

  it "returns a non-empty sorted list" do
    result = Platform::Types::Commands::FetchPermissions.new.call(context)
    result.should_not be_empty
    result.should eq(result.sort)
  end

  it "matches the query output exactly" do
    result = Platform::Types::Commands::FetchPermissions.new.call(context)
    result.should eq(Platform::Queries::Permissions.new.list)
  end

  it "includes the read_platform_types permission itself" do
    result = Platform::Types::Commands::FetchPermissions.new.call(context)
    result.should contain("read_platform_types")
  end
end

describe Platform::Types::Commands::FetchAccountTypes do
  context = make_types_context

  it "returns a non-empty sorted list" do
    result = Platform::Types::Commands::FetchAccountTypes.new.call(context)
    result.should_not be_empty
    result.should eq(result.sort)
  end

  it "matches the query output exactly" do
    result = Platform::Types::Commands::FetchAccountTypes.new.call(context)
    result.should eq(Platform::Queries::AccountTypes.new.list)
  end

  it "includes both public and internal account types" do
    result = Platform::Types::Commands::FetchAccountTypes.new.call(context)
    result.should contain("checking")
    result.should contain("settlement")
  end
end

describe Platform::Types::Commands::FetchCurrencies do
  context = make_types_context

  it "returns a non-empty sorted list" do
    result = Platform::Types::Commands::FetchCurrencies.new.call(context)
    result.should_not be_empty
    result.should eq(result.sort)
  end

  it "matches the query output exactly" do
    result = Platform::Types::Commands::FetchCurrencies.new.call(context)
    result.should eq(Platform::Queries::Currencies.new.list)
  end

  it "contains exactly the supported currencies" do
    result = Platform::Types::Commands::FetchCurrencies.new.call(context)
    result.size.should eq(CrystalBank::Types::Currencies::Supported.values.size)
    CrystalBank::Types::Currencies::Supported.values.each do |supported|
      result.should contain(supported.to_s)
    end
  end
end

describe Platform::Types::Commands::FetchCustomerTypes do
  context = make_types_context

  it "returns a non-empty sorted list" do
    result = Platform::Types::Commands::FetchCustomerTypes.new.call(context)
    result.should_not be_empty
    result.should eq(result.sort)
  end

  it "matches the query output exactly" do
    result = Platform::Types::Commands::FetchCustomerTypes.new.call(context)
    result.should eq(Platform::Queries::CustomerTypes.new.list)
  end

  it "contains exactly business and individual" do
    result = Platform::Types::Commands::FetchCustomerTypes.new.call(context)
    result.should eq(["business", "individual"])
  end
end

describe Platform::Types::Commands::FetchLedgerEntryTypes do
  context = make_types_context

  it "returns a non-empty sorted list" do
    result = Platform::Types::Commands::FetchLedgerEntryTypes.new.call(context)
    result.should_not be_empty
    result.should eq(result.sort)
  end

  it "matches the query output exactly" do
    result = Platform::Types::Commands::FetchLedgerEntryTypes.new.call(context)
    result.should eq(Platform::Queries::LedgerEntryTypes.new.list)
  end

  it "includes operational and principal entry types" do
    result = Platform::Types::Commands::FetchLedgerEntryTypes.new.call(context)
    result.should contain("principal")
    result.should contain("adjustment")
    result.should contain("reversal")
  end
end

describe Platform::Types::Commands::FetchPermissionGroups do
  context = make_types_context

  it "returns a non-empty list" do
    result = Platform::Types::Commands::FetchPermissionGroups.new.call(context)
    result.should_not be_empty
  end

  it "matches the query output exactly" do
    result = Platform::Types::Commands::FetchPermissionGroups.new.call(context)
    expected = Platform::Queries::PermissionGroups.new.list
    result.size.should eq(expected.size)
    result.zip(expected).each do |cmd_group, query_group|
      cmd_group.name.should eq(query_group.name)
      cmd_group.description.should eq(query_group.description)
      cmd_group.permissions.size.should eq(query_group.permissions.size)
    end
  end

  it "covers all defined permissions" do
    result = Platform::Types::Commands::FetchPermissionGroups.new.call(context)
    total = result.sum(&.permissions.size)
    total.should eq(CrystalBank::Permissions.values.size)
  end
end
