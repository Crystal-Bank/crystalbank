module CrystalBank::Domains::Users
  module Api
    class Me < CrystalBank::Api::Base
      base "/me"

      struct ScopeInfo
        include JSON::Serializable
        getter id : UUID
        getter name : String

        def initialize(@id : UUID, @name : String); end
      end

      struct MeResponse
        include JSON::Serializable
        getter user_id : UUID
        getter role_ids : Array(UUID)
        getter scope : ScopeInfo?

        def initialize(@user_id : UUID, @role_ids : Array(UUID), @scope : ScopeInfo?); end
      end

      # Me
      # Returns the context of the current caller: user_id, role_ids, and the user's registered scope
      #
      # Required permission:
      # - **read_me**
      @[AC::Route::GET("/")]
      def me : MeResponse
        authorized?("read_me", request_scope: false)

        user = ::Users::Queries::Users.new.get(context.user_id)
        scope_info = if user && (s = Scopes::Queries::Scopes.new.get(user.scope_id))
                       ScopeInfo.new(s.id, s.name)
                     end

        MeResponse.new(context.user_id, context.roles, scope_info)
      end
    end
  end
end
