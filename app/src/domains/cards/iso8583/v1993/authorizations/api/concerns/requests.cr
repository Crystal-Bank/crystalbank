module CrystalBank::Domains::Cards::Iso8583::V1993::Authorizations
  module Api
    module Requests
      struct AuthorizationRequest
        include JSON::Serializable

        property raw_message : String
        property scope_id : UUID
      end
    end
  end
end
