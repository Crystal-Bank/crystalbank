require "../../../spec_helper"

describe CrystalBank::Domains::Events::Queries::Events do
  available_scope_id = UUID.new("00000000-0000-0000-0000-100000000001")
  other_scope_id     = UUID.new("00000000-0000-0000-0000-200000000001")

  user_aggr_id  = UUID.v7
  scope_aggr_id = UUID.v7
  other_aggr_id = UUID.v7

  # Placeholders updated in before_all (Crystal closures capture by reference)
  user_event_id  = UUID.new("00000000-0000-0000-0000-000000000000")
  scope_event_id = UUID.new("00000000-0000-0000-0000-000000000000")
  other_event_id = UUID.new("00000000-0000-0000-0000-000000000000")

  before_all do
    projection = ::Events::Projections::Events.new

    # Two events in available_scope_id with different aggregate types/handles
    user_req = Test::User::Events::Onboarding::Requested.new.create(aggr_id: user_aggr_id)
    TEST_EVENT_STORE.append(user_req)
    projection.apply(user_req)
    user_event_id = user_req.header.event_id

    scope_req = Test::Scope::Events::Creation::Requested.new.create(aggr_id: scope_aggr_id)
    TEST_EVENT_STORE.append(scope_req)
    projection.apply(scope_req)
    scope_event_id = scope_req.header.event_id

    # One event in other_scope_id for scope isolation tests
    other_req = Scopes::Creation::Events::Requested.new(
      actor_id: UUID.new("00000000-0000-0000-0000-000000000000"),
      aggregate_id: other_aggr_id,
      name: "Other org",
      parent_scope_id: nil,
      scope_id: other_scope_id,
      command_handler: "test",
      comment: "test",
    )
    TEST_EVENT_STORE.append(other_req)
    projection.apply(other_req)
    other_event_id = other_req.header.event_id
  end

  describe "#list" do
    describe "without filters" do
      it "returns all events visible to the context scope" do
        context = CrystalBank::Api::Context.new(
          user_id: UUID.v7,
          roles: [] of UUID,
          required_permission: CrystalBank::Permissions::READ_events_list,
          scope: available_scope_id,
          available_scopes: [available_scope_id]
        )
        ids = ::Events::Queries::Events.new.list(context, cursor: nil, limit: 100).map(&.id)
        ids.should contain(user_event_id)
        ids.should contain(scope_event_id)
        ids.should_not contain(other_event_id)
      end
    end

    describe "filter by aggregate_id" do
      it "returns only events for the given aggregate" do
        context = CrystalBank::Api::Context.new(
          user_id: UUID.v7,
          roles: [] of UUID,
          required_permission: CrystalBank::Permissions::READ_events_list,
          scope: available_scope_id,
          available_scopes: [available_scope_id]
        )
        results = ::Events::Queries::Events.new.list(context, cursor: nil, limit: 100, aggregate_id: user_aggr_id)
        ids = results.map(&.id)
        ids.should contain(user_event_id)
        ids.should_not contain(scope_event_id)
      end

      it "returns empty for an aggregate_id that does not exist in scope" do
        context = CrystalBank::Api::Context.new(
          user_id: UUID.v7,
          roles: [] of UUID,
          required_permission: CrystalBank::Permissions::READ_events_list,
          scope: available_scope_id,
          available_scopes: [available_scope_id]
        )
        results = ::Events::Queries::Events.new.list(context, cursor: nil, limit: 100, aggregate_id: UUID.v7)
        results.should be_empty
      end
    end

    describe "filter by event_id" do
      it "returns exactly the event with the matching event_id" do
        context = CrystalBank::Api::Context.new(
          user_id: UUID.v7,
          roles: [] of UUID,
          required_permission: CrystalBank::Permissions::READ_events_list,
          scope: available_scope_id,
          available_scopes: [available_scope_id]
        )
        results = ::Events::Queries::Events.new.list(context, cursor: nil, limit: 100, event_id: user_event_id)
        results.size.should eq(1)
        results.first.id.should eq(user_event_id)
      end

      it "returns empty when the event_id belongs to a different scope" do
        context = CrystalBank::Api::Context.new(
          user_id: UUID.v7,
          roles: [] of UUID,
          required_permission: CrystalBank::Permissions::READ_events_list,
          scope: other_scope_id,
          available_scopes: [other_scope_id]
        )
        results = ::Events::Queries::Events.new.list(context, cursor: nil, limit: 100, event_id: user_event_id)
        results.should be_empty
      end
    end

    describe "filter by event_handle" do
      it "returns only events matching the handle" do
        context = CrystalBank::Api::Context.new(
          user_id: UUID.v7,
          roles: [] of UUID,
          required_permission: CrystalBank::Permissions::READ_events_list,
          scope: available_scope_id,
          available_scopes: [available_scope_id]
        )
        results = ::Events::Queries::Events.new.list(context, cursor: nil, limit: 100, event_handle: "user.onboarding.requested")
        ids = results.map(&.id)
        ids.should contain(user_event_id)
        ids.should_not contain(scope_event_id)
      end

      it "returns empty when no events match the handle in scope" do
        context = CrystalBank::Api::Context.new(
          user_id: UUID.v7,
          roles: [] of UUID,
          required_permission: CrystalBank::Permissions::READ_events_list,
          scope: available_scope_id,
          available_scopes: [available_scope_id]
        )
        results = ::Events::Queries::Events.new.list(context, cursor: nil, limit: 100, event_handle: "nonexistent.handle")
        results.should be_empty
      end
    end

    describe "scope isolation" do
      it "excludes events whose scope_id is outside available_scopes" do
        context = CrystalBank::Api::Context.new(
          user_id: UUID.v7,
          roles: [] of UUID,
          required_permission: CrystalBank::Permissions::READ_events_list,
          scope: other_scope_id,
          available_scopes: [other_scope_id]
        )
        ids = ::Events::Queries::Events.new.list(context, cursor: nil, limit: 100).map(&.id)
        ids.should contain(other_event_id)
        ids.should_not contain(user_event_id)
        ids.should_not contain(scope_event_id)
      end
    end

    describe "cursor pagination" do
      it "excludes events at or before the cursor" do
        context = CrystalBank::Api::Context.new(
          user_id: UUID.v7,
          roles: [] of UUID,
          required_permission: CrystalBank::Permissions::READ_events_list,
          scope: available_scope_id,
          available_scopes: [available_scope_id]
        )
        beyond = UUID.new("ffffffff-ffff-ffff-ffff-ffffffffffff")
        results = ::Events::Queries::Events.new.list(context, cursor: beyond, limit: 100)
        results.should be_empty
      end

      it "includes events at or after the cursor" do
        context = CrystalBank::Api::Context.new(
          user_id: UUID.v7,
          roles: [] of UUID,
          required_permission: CrystalBank::Permissions::READ_events_list,
          scope: available_scope_id,
          available_scopes: [available_scope_id]
        )
        results = ::Events::Queries::Events.new.list(context, cursor: user_event_id, limit: 100)
        ids = results.map(&.id)
        ids.should contain(user_event_id)
      end
    end
  end
end
