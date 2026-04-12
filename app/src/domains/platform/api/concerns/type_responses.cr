module CrystalBank::Domains::Platform
  module Api
    module TypeResponses
      struct TypesResponse
        include JSON::Serializable

        @[JSON::Field(description: "Sorted list of type values")]
        getter values : Array(String)

        def initialize(@values : Array(String))
        end
      end
    end
  end
end
