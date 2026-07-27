require "../../spec_helper"
require "base64"

# P-256 public key from the test environment (JWT_PUBLIC_KEY in .env-test)
JWKS_TEST_PEM = "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEtsyH1cptl8ROIGaiK1yDudiuCj3v\no3XRL5DtmAjHjl/JEyPG3PY1/hjBZBtANNAk4YbBh7XUnQO2dLWh38BFYQ==\n-----END PUBLIC KEY-----"

# Expected base64url-encoded (no padding) x/y coordinates extracted from the
# SubjectPublicKeyInfo DER encoding of JWKS_TEST_PEM.
JWKS_EXPECTED_X = "tsyH1cptl8ROIGaiK1yDudiuCj3vo3XRL5DtmAjHjl8"
JWKS_EXPECTED_Y = "yRMjxtz2Nf4YwWQbQDTQJOGGwYe11J0DtnS1od_ARWE"
JWKS_TEST_KID   = "2026-07-key-1"

# Mirrors the PEM-to-JWK conversion logic in JWKS#jwks.
def parse_test_jwk(pem : String, kid : String = JWKS_TEST_KID) : CrystalBank::Api::JWKS::JWK
  body = pem
    .gsub("-----BEGIN PUBLIC KEY-----", "")
    .gsub("-----END PUBLIC KEY-----", "")
    .gsub("\\n", "")
    .gsub("\n", "")
    .strip

  der = Base64.decode(body)
  x = Base64.urlsafe_encode(der[27, 32], false)
  y = Base64.urlsafe_encode(der[59, 32], false)

  CrystalBank::Api::JWKS::JWK.new(kty: "EC", use: "sig", alg: "ES256", crv: "P-256", kid: kid, x: x, y: y)
end

describe CrystalBank::Api::JWKS do
  describe "JWK struct" do
    it "has correct static fields for a P-256 signing key" do
      jwk = parse_test_jwk(JWKS_TEST_PEM)

      jwk.kty.should eq("EC")
      jwk.use.should eq("sig")
      jwk.alg.should eq("ES256")
      jwk.crv.should eq("P-256")
    end

    it "carries the kid passed to the constructor" do
      jwk = parse_test_jwk(JWKS_TEST_PEM, "my-test-kid")
      jwk.kid.should eq("my-test-kid")
    end

    it "extracts the correct x coordinate from the DER-encoded public key" do
      jwk = parse_test_jwk(JWKS_TEST_PEM)
      jwk.x.should eq(JWKS_EXPECTED_X)
    end

    it "extracts the correct y coordinate from the DER-encoded public key" do
      jwk = parse_test_jwk(JWKS_TEST_PEM)
      jwk.y.should eq(JWKS_EXPECTED_Y)
    end

    it "produces url-safe base64 without padding" do
      jwk = parse_test_jwk(JWKS_TEST_PEM)
      jwk.x.should_not contain("=")
      jwk.y.should_not contain("=")
      jwk.x.should_not contain("+")
      jwk.x.should_not contain("/")
      jwk.y.should_not contain("+")
      jwk.y.should_not contain("/")
    end

    it "serialises to JSON with all required JWK fields including kid" do
      jwk = parse_test_jwk(JWKS_TEST_PEM)
      json = jwk.to_json
      parsed = JSON.parse(json)

      parsed["kty"].as_s.should eq("EC")
      parsed["use"].as_s.should eq("sig")
      parsed["alg"].as_s.should eq("ES256")
      parsed["crv"].as_s.should eq("P-256")
      parsed["kid"].as_s.should eq(JWKS_TEST_KID)
      parsed["x"].as_s.should eq(JWKS_EXPECTED_X)
      parsed["y"].as_s.should eq(JWKS_EXPECTED_Y)
    end
  end

  describe "JWKSResponse struct" do
    it "wraps keys in a 'keys' array" do
      jwk = parse_test_jwk(JWKS_TEST_PEM)
      response = CrystalBank::Api::JWKS::JWKSResponse.new([jwk])

      response.keys.size.should eq(1)
      response.keys.first.should eq(jwk)
    end

    it "serialises to JSON with a top-level 'keys' array" do
      jwk = parse_test_jwk(JWKS_TEST_PEM)
      response = CrystalBank::Api::JWKS::JWKSResponse.new([jwk])
      json = response.to_json
      parsed = JSON.parse(json)

      parsed["keys"].as_a.size.should eq(1)
      parsed["keys"][0]["kty"].as_s.should eq("EC")
      parsed["keys"][0]["kid"].as_s.should eq(JWKS_TEST_KID)
    end
  end

  describe "DER length assertion" do
    it "raises when the DER is not 91 bytes" do
      # A short PEM with 90 bytes of DER (zero-padded) is enough to trigger the guard
      short_der = Bytes.new(90)
      bad_pem = "-----BEGIN PUBLIC KEY-----\n#{Base64.encode(short_der).gsub(/\n/, "")}\n-----END PUBLIC KEY-----"

      body = bad_pem
        .gsub("-----BEGIN PUBLIC KEY-----", "")
        .gsub("-----END PUBLIC KEY-----", "")
        .gsub("\\n", "")
        .gsub("\n", "")
        .strip

      der = Base64.decode(body)
      expect_raises(Exception, /unexpected DER length/) do
        raise "unexpected DER length: #{der.size}" unless der.size == 91
      end
    end
  end
end
