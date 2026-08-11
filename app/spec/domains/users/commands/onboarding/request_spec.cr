require "../../../../spec_helper"

describe CrystalBank::Domains::Users::Onboarding::Commands::RequestHandler do
  it "appends a Requested event under the given aggregate ID" do
    scope_id = UUID.v7
    request = Users::Api::Requests::OnboardingRequest.from_json(%({"name":"Jane Smith","email":"jane@example.com"}))

    user_id = UUID.v7
    Users::Onboarding::Commands::RequestHandler.new.handle(
      Users::Onboarding::Commands::Request.new(aggregate_id: user_id, name: request.name, email: request.email, scope_id: scope_id, actor_id: UUID.v7)
    )

    aggregate = Users::Aggregate.new(user_id)
    aggregate.hydrate

    aggregate.state.name.should eq("Jane Smith")
    aggregate.state.email.should eq("jane@example.com")
    aggregate.state.scope_id.should eq(scope_id)
    aggregate.state.onboarded.should be_false
  end
end
