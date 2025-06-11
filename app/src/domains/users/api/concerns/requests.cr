module CrystalBank::Domains::Users
  module Api
    module Requests
      struct AssignRolesRequest
        include JSON::Serializable

        @[JSON::Field(description: "UUID of the roles to be assigned to the user")]
        getter role_ids : Array(UUID)
      end

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
