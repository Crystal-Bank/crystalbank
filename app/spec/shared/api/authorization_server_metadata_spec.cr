require "../../spec_helper"

describe CrystalBank::Api::JWKS do
  describe "AuthorizationServerMetadata struct" do
    it "holds all required RFC 8414 fields" do
      meta = CrystalBank::Api::JWKS::AuthorizationServerMetadata.new(
        issuer: "https://api.crystalbank.xyz",
        jwks_uri: "https://api.crystalbank.xyz/.well-known/jwks.json",
        token_endpoint: "https://api.crystalbank.xyz/oauth/token",
        grant_types_supported: ["client_credentials"],
        response_types_supported: [] of String,
        token_endpoint_auth_methods_supported: ["client_secret_basic", "client_secret_post"],
        scopes_supported: ["read_accounts_list", "write_accounts_opening_request"]
      )

      meta.issuer.should eq("https://api.crystalbank.xyz")
      meta.jwks_uri.should eq("https://api.crystalbank.xyz/.well-known/jwks.json")
      meta.token_endpoint.should eq("https://api.crystalbank.xyz/oauth/token")
      meta.grant_types_supported.should eq(["client_credentials"])
      meta.response_types_supported.should eq([] of String)
      meta.token_endpoint_auth_methods_supported.should eq(["client_secret_basic", "client_secret_post"])
    end

    it "serialises to JSON with the correct RFC 8414 shape" do
      meta = CrystalBank::Api::JWKS::AuthorizationServerMetadata.new(
        issuer: "https://api.crystalbank.xyz",
        jwks_uri: "https://api.crystalbank.xyz/.well-known/jwks.json",
        token_endpoint: "https://api.crystalbank.xyz/oauth/token",
        grant_types_supported: ["client_credentials"],
        response_types_supported: [] of String,
        token_endpoint_auth_methods_supported: ["client_secret_basic", "client_secret_post"],
        scopes_supported: ["read_accounts_list"]
      )
      json = meta.to_json
      parsed = JSON.parse(json)

      parsed["issuer"].as_s.should eq("https://api.crystalbank.xyz")
      parsed["jwks_uri"].as_s.should eq("https://api.crystalbank.xyz/.well-known/jwks.json")
      parsed["token_endpoint"].as_s.should eq("https://api.crystalbank.xyz/oauth/token")
      parsed["grant_types_supported"].as_a.map(&.as_s).should eq(["client_credentials"])
      parsed["response_types_supported"].as_a.should be_empty
      parsed["token_endpoint_auth_methods_supported"].as_a.map(&.as_s).should contain("client_secret_basic")
      parsed["token_endpoint_auth_methods_supported"].as_a.map(&.as_s).should contain("client_secret_post")
      parsed["scopes_supported"].as_a.should_not be_nil

      # Must not contain OpenID Connect fields
      parsed.as_h.keys.should_not contain("id_token_signing_alg_values_supported")
      parsed.as_h.keys.should_not contain("authorization_endpoint")
    end

    it "derives jwks_uri from issuer and does not have an independent jwks_uri config" do
      issuer = CrystalBank::Env.issuer
      meta = CrystalBank::Api::JWKS::AuthorizationServerMetadata.new(
        issuer: issuer,
        jwks_uri: "#{issuer}/.well-known/jwks.json",
        token_endpoint: "#{issuer}/oauth/token",
        grant_types_supported: ["client_credentials"],
        response_types_supported: [] of String,
        token_endpoint_auth_methods_supported: ["client_secret_basic", "client_secret_post"],
        scopes_supported: CrystalBank::Permissions.values.map(&.to_s)
      )

      meta.issuer.should eq(meta.jwks_uri.sub("/.well-known/jwks.json", ""))
    end

    it "scopes_supported matches the CrystalBank::Permissions enum" do
      meta = CrystalBank::Api::JWKS::AuthorizationServerMetadata.new(
        issuer: "https://api.crystalbank.xyz",
        jwks_uri: "https://api.crystalbank.xyz/.well-known/jwks.json",
        token_endpoint: "https://api.crystalbank.xyz/oauth/token",
        grant_types_supported: ["client_credentials"],
        response_types_supported: [] of String,
        token_endpoint_auth_methods_supported: ["client_secret_basic", "client_secret_post"],
        scopes_supported: CrystalBank::Permissions.values.map(&.to_s)
      )

      meta.scopes_supported.should contain("read_accounts_list")
      meta.scopes_supported.should contain("write_accounts_opening_request")
      meta.scopes_supported.size.should eq(CrystalBank::Permissions.values.size)
    end
  end
end
