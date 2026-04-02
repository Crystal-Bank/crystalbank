module CrystalBank
  module Api
    class OpenAPI < ::AC::Base
      base "/openapi"

      DOCS = {{ read_file("#{__DIR__}/../../openapi.yaml") }}

      get "/docs" do
        render yaml: DOCS
      end
    end
  end
end
