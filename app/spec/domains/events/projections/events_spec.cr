require "../../../spec_helper"

describe CrystalBank::Domains::Events::Projections::Events do
  describe "#apply" do
    describe "Category A — events with scope_id in body" do
      it "stores the event with scope_id extracted from the body" do
        aggr_id = UUID.v7
        req = Test::User::Events::Onboarding::Requested.new.create(aggr_id: aggr_id)
        TEST_EVENT_STORE.append(req)
        ::Events::Projections::Events.new.apply(req)

        count = TEST_PROJECTION_DB.scalar %(
          SELECT COUNT(*) FROM projections.events
          WHERE aggregate_id = $1
            AND scope_id = '00000000-0000-0000-0000-100000000001'::uuid
        ), aggr_id
        count.should eq(1)
      end
    end

    describe "Category B — events without scope_id in body" do
      it "derives scope_id from the Requested event already in the projection" do
        aggr_id = UUID.v7
        projection = ::Events::Projections::Events.new

        req = Test::User::Events::Onboarding::Requested.new.create(aggr_id: aggr_id)
        TEST_EVENT_STORE.append(req)
        projection.apply(req)

        acc = Test::User::Events::Onboarding::Accepted.new.create(aggr_id: aggr_id)
        TEST_EVENT_STORE.append(acc)
        projection.apply(acc)

        count = TEST_PROJECTION_DB.scalar %(
          SELECT COUNT(*) FROM projections.events
          WHERE aggregate_id = $1
            AND scope_id = '00000000-0000-0000-0000-100000000001'::uuid
        ), aggr_id
        count.should eq(2)
      end
    end

    describe "header and body storage" do
      it "stores the header with the correct aggregate_id" do
        aggr_id = UUID.v7
        req = Test::User::Events::Onboarding::Requested.new.create(aggr_id: aggr_id)
        TEST_EVENT_STORE.append(req)
        ::Events::Projections::Events.new.apply(req)

        header_text = TEST_PROJECTION_DB.query_one %(
          SELECT header::text FROM projections.events WHERE aggregate_id = $1
        ), aggr_id, as: String
        header = JSON.parse(header_text)
        header["aggregate_id"].as_s.should eq(aggr_id.to_s)
      end

      it "stores the body with scope_id for Requested events" do
        aggr_id = UUID.v7
        req = Test::User::Events::Onboarding::Requested.new.create(aggr_id: aggr_id)
        TEST_EVENT_STORE.append(req)
        ::Events::Projections::Events.new.apply(req)

        body_text = TEST_PROJECTION_DB.query_one %(
          SELECT body::text FROM projections.events WHERE aggregate_id = $1
        ), aggr_id, as: String
        body = JSON.parse(body_text)
        body["scope_id"].as_s.should eq("00000000-0000-0000-0000-100000000001")
      end

      it "stores a null body for events with no body attributes" do
        aggr_id = UUID.v7
        projection = ::Events::Projections::Events.new

        req = Test::User::Events::Onboarding::Requested.new.create(aggr_id: aggr_id)
        TEST_EVENT_STORE.append(req)
        projection.apply(req)

        acc = Test::User::Events::Onboarding::Accepted.new.create(aggr_id: aggr_id)
        TEST_EVENT_STORE.append(acc)
        projection.apply(acc)

        body_null = TEST_PROJECTION_DB.query_one %(
          SELECT body IS NULL FROM projections.events
          WHERE aggregate_id = $1 AND aggregate_version = 2
        ), aggr_id, as: Bool
        body_null.should be_true
      end
    end
  end
end
