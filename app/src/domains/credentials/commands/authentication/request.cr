module CrystalBank::Domains::Credentials
  module Authentication
    module Commands
      class Request < ES::Command
        class TotpRequired < ::Exception; end

        def call(email : String, password : String, totp_code : String?) : String
          user = Credentials::Repositories::Users.new.fetch_by_email!(email)
          credential = Credentials::Queries::Credentials.new.get(user.id)

          unless credential && credential.status == "active" && credential.password_hash
            raise CrystalBank::Exception::Authentication.new("Invalid login credentials", HTTP::Status::UNAUTHORIZED)
          end

          bcrypt = Crypto::Bcrypt::Password.new(credential.password_hash.as(String))
          unless bcrypt.verify(password)
            raise CrystalBank::Exception::Authentication.new("Invalid login credentials", HTTP::Status::UNAUTHORIZED)
          end

          if credential.totp_active
            raise TotpRequired.new if totp_code.nil?
            encrypted = credential.totp_encrypted_secret.as(String)
            secret = CrystalBank::Services::TOTP.decrypt_secret(encrypted)
            unless CrystalBank::Services::TOTP.verify(secret, totp_code)
              raise CrystalBank::Exception::Authentication.new("Invalid TOTP code", HTTP::Status::UNAUTHORIZED)
            end
          end

          payload = CrystalBank::Api::JWT.new(roles: user.role_ids, user_id: user.id)
          JWT.encode(payload, CrystalBank::Env.jwt_private_key, JWT::Algorithm::ES256)
        end
      end
    end
  end
end
