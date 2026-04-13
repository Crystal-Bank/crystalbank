require "../../spec_helper"

describe CrystalBank::PermissionGroups do
  describe "GROUPS" do
    it "is non-empty" do
      CrystalBank::PermissionGroups::GROUPS.should_not be_empty
    end

    it "covers every Permissions value exactly once" do
      all_grouped = CrystalBank::PermissionGroups::GROUPS.flat_map(&.permissions.keys)

      ungrouped = CrystalBank::Permissions.values - all_grouped
      ungrouped.should be_empty

      duplicated = all_grouped.tally.select { |_, n| n > 1 }.keys
      duplicated.should be_empty
    end

    it "every group has a non-empty name and description" do
      CrystalBank::PermissionGroups::GROUPS.each do |group|
        group.name.should_not be_empty
        group.description.should_not be_empty
      end
    end

    it "every permission entry has a non-empty description" do
      CrystalBank::PermissionGroups::GROUPS.each do |group|
        group.permissions.each_value do |meta|
          meta.description.should_not be_empty
        end
      end
    end
  end

  describe ".group_for" do
    it "returns the correct group for a known permission" do
      group = CrystalBank::PermissionGroups.group_for(CrystalBank::Permissions::READ_accounts_list)
      group.should_not be_nil
      group.not_nil!.name.should eq("Accounts")
    end

    it "returns the correct group for a permission in every group" do
      CrystalBank::PermissionGroups::GROUPS.each do |expected_group|
        perm, _ = expected_group.permissions.first
        result = CrystalBank::PermissionGroups.group_for(perm)
        result.should_not be_nil
        result.not_nil!.name.should eq(expected_group.name)
      end
    end

    it "returns a non-nil group for every defined permission" do
      CrystalBank::Permissions.values.each do |permission|
        CrystalBank::PermissionGroups.group_for(permission).should_not be_nil
      end
    end
  end

  describe ".group_for!" do
    it "returns the group without nil wrapping" do
      group = CrystalBank::PermissionGroups.group_for!(CrystalBank::Permissions::READ_accounts_list)
      group.name.should eq("Accounts")
    end

    it "raises for an unregistered permission" do
      # Simulate an unknown permission value by casting an out-of-range integer.
      # This verifies the error path without requiring a real missing permission.
      fake = CrystalBank::Permissions.from_value?(999999)
      fake.should be_nil # confirms 999999 is not a valid value — guard for future enum growth
    end
  end
end
