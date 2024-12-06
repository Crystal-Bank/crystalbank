module CrystalBank::Domains::Users
  module Api
    module Requests
      struct OnboardingRequest
        include JSON::Serializable

        @[JSON::Field(description: "Name of the user")]
        getter name : String

        @[JSON::Field(format: "email", description: "Email address of the user")]
        getter email : String
      end
    end
  end
end
