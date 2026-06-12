module CrystalBank::Domains::Cards::Iso8583::V1987::Authorizations
  module Api
    module Responses
      struct AuthorizationResponse
        include JSON::Serializable

        property authorization_id : UUID
        property status : String
      end
    end
  end
end
