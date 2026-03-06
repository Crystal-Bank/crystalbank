module CrystalBank
  module Api
    class OpenAPI < ::AC::Base
      base "/openapi"

      {% begin %}
        VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}
      {% end %}

      def self.docs : String
        AC::OpenAPI.generate_open_api_docs(
          title: "Application",
          version: VERSION,
          description: "OpenAPI docs for the CrystalBank project"
        ).merge(NamedTuple.new(servers: CrystalBank::Env.api_domains.map { |url| {url: url} })).to_json
      end

      get "/docs" do
        render yaml: self.class.docs.to_yaml
      end
    end
  end
end
