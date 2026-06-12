module CrystalBank::Domains::Cards::Iso8583::V1987::Authorizations
  module Api
    module Requests
      struct AuthorizationRequest
        include JSON::Serializable

        # Base64-encoded raw ISO 8583 message bytes
        property raw_message : String
        property scope_id : UUID
      end
    end
  end
end
