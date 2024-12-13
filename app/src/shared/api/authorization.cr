module CrystalBank
  module Api
    module Authorization
      def authorized?(permission : String? = nil, request_scope : Bool = true)
        token = request.headers["authorization"]?
        raise CrystalBank::Exception::InvalidArgument.new("authorization header is missing") if token.nil?
        raise CrystalBank::Exception::InvalidArgument.new("Invalid token format") unless token.includes?("Bearer")

        # Check jwt and extract data from it
        jwt = parse_jwt(token)

        # Get the request scope from the header
        request_scope_value = request.headers["x-scope"]?
        scope_id = if request_scope
                     raise CrystalBank::Exception::InvalidArgument.new("proving 'x-scope' header is mandatory") if (request_scope_value.nil? || request_scope_value.empty?)
                     UUID.new(request_scope_value)
                   end

        # return if no permission is requested
        return true if permission.nil?
      end

      private def parse_jwt(token : String) : CrystalBank::Api::JWT
        jwt = token.split(" ").last
        payload, _ = begin
          ::JWT.decode(jwt, CrystalBank::Env.jwt_public_key, ::JWT::Algorithm::ES256)
        rescue e : ::JWT::VerificationError
          raise CrystalBank::Exception::Authentication.new("Token verification failed", HTTP::Status::BAD_REQUEST)
        rescue e : ::JWT::ExpiredSignatureError
          raise CrystalBank::Exception::Authentication.new("Token expired", HTTP::Status::UNAUTHORIZED)
        rescue e : ::JWT::Error
          raise CrystalBank::Exception::Authentication.new("Invalid token", HTTP::Status::BAD_REQUEST)
        end

        jwt_payload = CrystalBank::Api::JWT.from_json(payload.to_json)
        raise CrystalBank::Exception::Authentication.new("Token payload is invalid", HTTP::Status::BAD_REQUEST) if jwt_payload.nil?

        jwt_payload
      end
    end
  end
end

# def authorized?(permission : String? = nil, request_scope : Bool = true)
# ....

#   available_scopes = CrystalBank::Services::AccessControl.new(roles: jwt.data.roles).available_scopes(permission)

#   session = CrystalBank::Objects::SessionContext.new(jwt.data.user, jwt.data.roles, permission, scope_id, available_scopes)
#   # TODO: raise CrystalBank::Exception::Authorization.new("Provided scope '#{x_scope}' is not in the list of available scopes #{jwt.data.scopes}") unless session.available_scopes.includes?(parsed_x_scope)
#   @session = session

#   return true unless available_scopes.empty?
#   raise CrystalBank::Exception::Authorization.new("No permission to perform this action '#{permission}'")
# end
