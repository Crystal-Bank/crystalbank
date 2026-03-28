require "../../../spec_helper"

describe CrystalBank::Domains::Accounts::Projections::AccountBlocks do
  it "inserts a row when a block is applied to an account" do
    projection = Accounts::Projections::AccountBlocks.new
    account_id = UUID.v7
    actor_id = UUID.v7

    applied = Test::Account::Events::Blocking::Applied.new.create(
      aggr_id: account_id,
      block_type: CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      actor_id: actor_id,
      reason: "AML screening"
    )

    projection.apply(applied)

    count = TEST_PROJECTION_DB.scalar %(
      SELECT COUNT(*) FROM projections.account_blocks
      WHERE account_uuid = $1 AND block_type = 'compliance_block' AND removed_at IS NULL
    ), account_id
    count.should eq(1)
  end

  it "sets removed_at when a block is removed from an account" do
    projection = Accounts::Projections::AccountBlocks.new
    account_id = UUID.v7
    actor_id = UUID.v7

    # First apply the block
    applied = Test::Account::Events::Blocking::Applied.new.create(
      aggr_id: account_id,
      block_type: CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      actor_id: actor_id,
      aggregate_version: 3
    )
    projection.apply(applied)

    # Then remove it
    removed = Test::Account::Events::Blocking::Removed.new.create(
      aggr_id: account_id,
      block_type: CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      actor_id: actor_id,
      aggregate_version: 4
    )
    projection.apply(removed)

    count = TEST_PROJECTION_DB.scalar %(
      SELECT COUNT(*) FROM projections.account_blocks
      WHERE account_uuid = $1 AND block_type = 'compliance_block' AND removed_at IS NOT NULL
    ), account_id
    count.should eq(1)
  end

  it "handles multiple block types independently" do
    projection = Accounts::Projections::AccountBlocks.new
    account_id = UUID.v7

    compliance = Test::Account::Events::Blocking::Applied.new.create(
      aggr_id: account_id,
      block_type: CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      aggregate_version: 3
    )
    operations = Test::Account::Events::Blocking::Applied.new.create(
      aggr_id: account_id,
      block_type: CrystalBank::Types::Accounts::BlockType::OPERATIONS_BLOCK,
      aggregate_version: 4
    )

    projection.apply(compliance)
    projection.apply(operations)

    active_count = TEST_PROJECTION_DB.scalar %(
      SELECT COUNT(*) FROM projections.account_blocks
      WHERE account_uuid = $1 AND removed_at IS NULL
    ), account_id
    active_count.should eq(2)
  end

  it "re-applying an existing block type upserts the row and clears removed_at" do
    projection = Accounts::Projections::AccountBlocks.new
    account_id = UUID.v7

    applied_first = Test::Account::Events::Blocking::Applied.new.create(
      aggr_id: account_id,
      block_type: CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      aggregate_version: 3
    )
    removed = Test::Account::Events::Blocking::Removed.new.create(
      aggr_id: account_id,
      block_type: CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      aggregate_version: 4
    )
    applied_again = Test::Account::Events::Blocking::Applied.new.create(
      aggr_id: account_id,
      block_type: CrystalBank::Types::Accounts::BlockType::COMPLIANCE_BLOCK,
      aggregate_version: 5
    )

    projection.apply(applied_first)
    projection.apply(removed)
    projection.apply(applied_again)

    # Should have exactly one row with removed_at = NULL
    count = TEST_PROJECTION_DB.scalar %(
      SELECT COUNT(*) FROM projections.account_blocks
      WHERE account_uuid = $1 AND block_type = 'compliance_block' AND removed_at IS NULL
    ), account_id
    count.should eq(1)
  end
end
