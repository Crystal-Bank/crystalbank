module CrystalBank::Domains::Users
  module Api
    module Responses
      # Response to an user onboarding request
      struct OnboardingResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the requested user")]
        getter id : UUID

        def initialize(@id : UUID)
        end
      end

      # Respond with a single user entity
      struct User
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the requested user")]
        getter id : UUID

        @[JSON::Field(description: "Name of the user")]
        getter name : String

        @[JSON::Field(format: "email", description: "Email address of the user")]
        getter email : String

        def initialize(
          @id : UUID,
          @name : String,
          @email : String
        ); end
      end
    end
  end
end
