module CrystalBank::Domains::Accounts
  module Virtual
    module Queries
      class VirtualAccounts
        struct VirtualAccount
          include DB::Serializable
          include DB::Serializable::NonStrict
          include JSON::Serializable

          @[DB::Field(key: "uuid")]
          getter id : UUID
          getter parent_account_id : UUID
          getter scope_id : UUID
          getter name : String
          getter object : String = "virtual_account"
          getter status : String

          @[DB::Field(converter: CrystalBank::Converters::GenericArray(CrystalBank::Types::Currencies::Supported))]
          getter currencies = Array(CrystalBank::Types::Currencies::Supported).new

          @[DB::Field(converter: CrystalBank::Converters::UUIDArray)]
          getter customer_ids = Array(UUID).new
        end

        def initialize
          @db = ES::Config.projection_database
        end

        def find(uuid : UUID) : VirtualAccount?
          @db.query_one?(
            %(SELECT * FROM "projections"."virtual_accounts" WHERE "uuid" = $1),
            uuid,
            as: VirtualAccount
          )
        end

        def list(
          parent_account_id : UUID,
          context : CrystalBank::Api::Context,
          cursor : UUID?,
          limit : Int32,
        ) : Array(VirtualAccount)
          query_param_counter = 0
          query = [] of String
          query_params = Array(Array(UUID) | UUID? | Int32).new

          query << %(SELECT * FROM "projections"."virtual_accounts" WHERE 1=1)

          query << %(AND "parent_account_id" = $#{query_param_counter += 1})
          query_params << parent_account_id

          query << %(AND "scope_id" = ANY($#{query_param_counter += 1}::uuid[]))
          query_params << context.available_scopes

          unless cursor.nil?
            query << %(AND "uuid" >= $#{query_param_counter += 1})
            query_params << cursor
          end

          query << %(ORDER BY "uuid" ASC)
          query << %(LIMIT $#{query_param_counter += 1})
          query_params << limit

          @db.query_all(query.join(" "), args: query_params, as: VirtualAccount)
        end

        def any_non_inactive?(parent_account_id : UUID) : Bool
          @db.query_one(
            %(SELECT EXISTS (SELECT 1 FROM "projections"."virtual_accounts" WHERE "parent_account_id" = $1 AND "status" != 'inactive')),
            parent_account_id,
            as: Bool
          )
        end
      end
    end
  end
end
