module CrystalBank::Domains::Customers
  module Api
    module Responses
      # Response to a customer onboarding request
      struct OnboardingResponse
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the requested customer")]
        getter id : UUID

        def initialize(@id : UUID)
        end
      end

      # Respond with a single customer entity
      struct Customer
        include JSON::Serializable

        @[JSON::Field(format: "uuid", description: "ID of the requested customer")]
        getter id : UUID

        @[JSON::Field(description: "Name of the customer")]
        getter name : String

        @[JSON::Field(description: "Type of the customer")]
        getter type : CrystalBank::Types::Customers::Type

        def initialize(
          @id : UUID,
          @name : String,
          @type : CrystalBank::Types::Customers::Type,
        ); end
      end
    end
  end
end
