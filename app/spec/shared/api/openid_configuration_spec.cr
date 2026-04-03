require "../../spec_helper"

describe CrystalBank::Api::JWKS do
  describe "OpenIDConfiguration struct" do
    it "holds issuer, jwks_uri, and id_token_signing_alg_values_supported" do
      config = CrystalBank::Api::JWKS::OpenIDConfiguration.new(
        issuer: "https://api.crystalbank.xyz",
        jwks_uri: "https://api.crystalbank.xyz/.well-known/jwks.json",
        id_token_signing_alg_values_supported: ["ES256"]
      )

      config.issuer.should eq("https://api.crystalbank.xyz")
      config.jwks_uri.should eq("https://api.crystalbank.xyz/.well-known/jwks.json")
      config.id_token_signing_alg_values_supported.should eq(["ES256"])
    end

    it "serialises to JSON with all required OpenID Connect discovery fields" do
      config = CrystalBank::Api::JWKS::OpenIDConfiguration.new(
        issuer: "https://api.crystalbank.xyz",
        jwks_uri: "https://api.crystalbank.xyz/.well-known/jwks.json",
        id_token_signing_alg_values_supported: ["ES256"]
      )
      json = config.to_json
      parsed = JSON.parse(json)

      parsed["issuer"].as_s.should eq("https://api.crystalbank.xyz")
      parsed["jwks_uri"].as_s.should eq("https://api.crystalbank.xyz/.well-known/jwks.json")
      parsed["id_token_signing_alg_values_supported"].as_a.map(&.as_s).should eq(["ES256"])
    end
  end
end
