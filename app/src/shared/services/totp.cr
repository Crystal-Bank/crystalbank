require "openssl"
require "openssl/cipher"
require "openssl/hmac"

module CrystalBank
  module Services
    module TOTP
      STEP   = 30_u64
      DIGITS =      6
      ALPHA  = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

      def self.generate_secret : String
        base32_encode(Random::Secure.random_bytes(20))
      end

      def self.encrypt_secret(base32_secret : String) : String
        key = CrystalBank::Env.totp_encryption_key.hexbytes
        iv = Random::Secure.random_bytes(12)
        cipher = OpenSSL::Cipher.new("aes-256-gcm")
        cipher.encrypt
        cipher.key = key
        cipher.iv = iv
        ct = cipher.update(base32_secret.to_slice) + cipher.final
        tag = cipher.auth_tag(16)
        "#{iv.hexstring}:#{ct.hexstring}:#{tag.hexstring}"
      end

      def self.decrypt_secret(encrypted : String) : String
        parts = encrypted.split(":")
        iv = parts[0].hexbytes
        ct = parts[1].hexbytes
        tag = parts[2].hexbytes
        key = CrystalBank::Env.totp_encryption_key.hexbytes
        cipher = OpenSSL::Cipher.new("aes-256-gcm")
        cipher.decrypt
        cipher.key = key
        cipher.iv = iv
        cipher.auth_tag = tag
        plaintext = cipher.update(ct) + cipher.final
        String.new(plaintext)
      end

      def self.hotp(secret_base32 : String, counter : UInt64) : String
        key = base32_decode(secret_base32)
        msg = Bytes.new(8)
        c = counter
        7.downto(0) { |i| msg[i] = (c & 0xff_u64).to_u8; c >>= 8 }
        hmac = OpenSSL::HMAC.digest(:sha1, key, msg)
        offset = hmac[19].to_i & 0x0f
        code = ((hmac[offset].to_u32 & 0x7f_u32) << 24 |
                (hmac[offset + 1].to_u32 & 0xff_u32) << 16 |
                (hmac[offset + 2].to_u32 & 0xff_u32) << 8 |
                (hmac[offset + 3].to_u32 & 0xff_u32)) % (10_u32 ** DIGITS)
        code.to_s.rjust(DIGITS, '0')
      end

      def self.verify(secret_base32 : String, code : String) : Bool
        t = (Time.utc.to_unix.to_u64) / STEP
        (-1..1).any? { |drift| hotp(secret_base32, (t.to_i64 + drift).to_u64) == code }
      end

      def self.uri(secret_base32 : String, email : String) : String
        encoded = URI.encode_path(email)
        "otpauth://totp/CrystalBank:#{encoded}?secret=#{secret_base32}&issuer=CrystalBank&digits=6&period=30"
      end

      private def self.base32_encode(bytes : Bytes) : String
        result = String::Builder.new
        buf = 0_u64
        bits = 0
        bytes.each do |b|
          buf = (buf << 8) | b.to_u64
          bits += 8
          while bits >= 5
            bits -= 5
            result << ALPHA[(buf >> bits) & 0x1f]
          end
        end
        result << ALPHA[(buf << (5 - bits)) & 0x1f] if bits > 0
        result.to_s
      end

      private def self.base32_decode(str : String) : Bytes
        buf = 0_u64
        bits = 0
        result = [] of UInt8
        str.upcase.each_char do |c|
          idx = ALPHA.index(c)
          next unless idx
          buf = (buf << 5) | idx.to_u64
          bits += 5
          if bits >= 8
            bits -= 8
            result << ((buf >> bits) & 0xff).to_u8
          end
        end
        Bytes.new(result.size) { |i| result[i] }
      end
    end
  end
end
