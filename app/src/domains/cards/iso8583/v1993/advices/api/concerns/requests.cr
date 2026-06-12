module CrystalBank::Domains::Cards::Iso8583::V1993::Advices
  module Api
    module Requests
      struct AdviceRequest
        include JSON::Serializable

        property raw_message : String
        property scope_id : UUID
        property original_authorization_id : UUID?
      end
    end
  end
end
