require "./concerns/responses"

module CrystalBank::Domains::Platform
  module Api
    class Platform < CrystalBank::Api::Base
      include CrystalBank::Domains::Platform::Api::Responses
      base "/platform"
    end
  end
end
