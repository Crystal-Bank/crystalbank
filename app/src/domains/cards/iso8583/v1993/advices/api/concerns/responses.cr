module CrystalBank::Domains::Cards::Iso8583::V1993::Advices
  module Api
    module Responses
      struct AdviceResponse
        include JSON::Serializable

        property advice_id : UUID
        property status : String
      end
    end
  end
end
