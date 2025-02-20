module CrystalBank
  module Api
    class Context
      getter available_scopes = [] of UUID
      getter roles = [] of UUID
      getter scope : UUID?
      getter user_id : UUID

      def initialize(@user_id : UUID,
                     @roles : Array(UUID),
                     @required_permission : CrystalBank::Permissions,
                     @scope : UUID?,
                     @available_scopes : Array(UUID))
      end
    end
  end
end
