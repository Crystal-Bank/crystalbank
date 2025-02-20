module CrystalBank
  module Api
    module Authorization
      def authorized?(permission : String? = nil, request_scope : Bool = true)
        token = request.headers["authorization"]?
        scope = request.headers["x-scope"]?

        raise CrystalBank::Exception::InvalidArgument.new("authorization header is missing") if token.nil?
        raise CrystalBank::Exception::InvalidArgument.new("Invalid token format") unless token.includes?("Bearer")
        raise CrystalBank::Exception::InvalidArgument.new("x-scope header is missing") if request_scope && (scope.nil? || scope.empty?)

        # Check jwt and extract data from it
        jwt = parse_jwt(token)

        # Get the request scope from the header
        scope_id = UUID.new(scope.to_s) if request_scope

        # Authorize if no permission is requested
        return true if permission.nil?
        parsed_permissions = CrystalBank::Permissions.parse(permission)

        # Fetch available scopes
        available_scopes = CrystalBank::Services::AccessControl.new(roles: jwt.data.roles).available_scopes(parsed_permissions)

        # Create a session object
        @context = CrystalBank::Api::Context.new(jwt.data.user, jwt.data.roles, parsed_permissions, scope_id, available_scopes)

        return true unless available_scopes.empty?
        raise CrystalBank::Exception::Authorization.new("No permission to perform this action '#{permission}'")
      end

      private def parse_request_scope(scope : String?) : UUID
        raise CrystalBank::Exception::InvalidArgument.new("proving 'x-scope' header is mandatory") if (scope.nil? || scope.empty?)
        UUID.new(scope)
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
