require "../../../../spec_helper"

describe CrystalBank::Domains::Users::Onboarding::Commands::Request do
  it "appends a Requested event and returns the aggregate ID" do
    scope_id = UUID.v7
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_users_onboarding_request,
      scope: scope_id,
      available_scopes: [scope_id]
    )

    request = Users::Api::Requests::OnboardingRequest.from_json(%({"name":"Jane Smith","email":"jane@example.com"}))

    user_id = Users::Onboarding::Commands::Request.new.call(request, context)

    user_id.should be_a(UUID)

    aggregate = Users::Aggregate.new(user_id)
    aggregate.hydrate

    aggregate.state.name.should eq("Jane Smith")
    aggregate.state.email.should eq("jane@example.com")
    aggregate.state.scope_id.should eq(scope_id)
    aggregate.state.onboarded.should be_false
  end

  it "raises when scope is missing from context" do
    context = CrystalBank::Api::Context.new(
      user_id: UUID.v7,
      roles: [] of UUID,
      required_permission: CrystalBank::Permissions::WRITE_users_onboarding_request,
      scope: nil,
      available_scopes: [] of UUID
    )

    request = Users::Api::Requests::OnboardingRequest.from_json(%({"name":"Jane Smith","email":"jane@example.com"}))

    expect_raises(CrystalBank::Exception::InvalidArgument, /Invalid scope/) do
      Users::Onboarding::Commands::Request.new.call(request, context)
    end
  end
end
