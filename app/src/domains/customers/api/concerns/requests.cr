module CrystalBank::Domains::Customers
  module Api
    module Requests
      struct OnboardingRequest
        include JSON::Serializable

        # @[JSON::Field(description: "Address of the customer")]
        # getter address :

        @[JSON::Field(description: "Name of the customer")]
        getter name : String

        @[JSON::Field(description: "Type of the customer")]
        getter type : CrystalBank::Types::Customers::Type
      end
    end
  end
end
