module CrystalBank::Domains::Customers
  module Api
    module Requests
      struct OnboardingRequest
        include JSON::Serializable

        @[JSON::Field(description: "Name of the customer. Needs to be at least 2 characters long")]
        getter name : String

        @[JSON::Field(description: "Type of the customer")]
        getter type : CrystalBank::Types::Customers::Type
      end
    end
  end
end
