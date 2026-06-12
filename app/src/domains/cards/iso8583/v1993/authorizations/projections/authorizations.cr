module CrystalBank::Domains::Cards::Iso8583::V1993::Authorizations
  module Projections
    class Authorizations < ES::Projection
      define_projection "projections.iso8583_v1993_authorizations", init: true do
        column :id,            Int32,  serial: true, primary_key: true
        column :uuid,          UUID,   null: false
        column :stan,          String, null: false
        column :pan_masked,    String, null: false
        column :amount,        Int64,  null: false
        column :currency,      String, null: false
        column :terminal_id,   String, null: false
        column :merchant_id,   String, null: false
        column :account_id_1,  String
        column :account_id_2,  String
        column :scope_id,      UUID,   null: false
        column :auth_code,     String
        column :response_code, String
        column :status,        String, null: false, default: "pending"
        column :created_at,    Time,   null: false
        column :updated_at,    Time,   null: false

        index [:uuid],    unique: true
        index [:stan]
        index [:scope_id]
      end

      apply(V1993::Authorizations::Request::Events::Received) do |event|
        @projection_database.transaction do |tx|
          tx.exec(<<-SQL, event.header.aggregate_id, event.stan, event.pan_masked,
            INSERT INTO projections.iso8583_v1993_authorizations
              (uuid, stan, pan_masked, amount, currency, terminal_id, merchant_id,
               account_id_1, account_id_2, scope_id, status, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'pending', NOW(), NOW())
          SQL
            event.amount, event.currency, event.terminal_id, event.merchant_id,
            event.account_id_1, event.account_id_2, event.scope_id)
        end
      end

      apply(V1993::Authorizations::Response::Events::Approved) do |event|
        @projection_database.transaction do |tx|
          tx.exec(<<-SQL, event.header.aggregate_id, event.auth_code, event.response_code)
            UPDATE projections.iso8583_v1993_authorizations
            SET status = 'approved', auth_code = $2, response_code = $3, updated_at = NOW()
            WHERE uuid = $1
          SQL
        end
      end

      apply(V1993::Authorizations::Response::Events::Declined) do |event|
        @projection_database.transaction do |tx|
          tx.exec(<<-SQL, event.header.aggregate_id, event.response_code)
            UPDATE projections.iso8583_v1993_authorizations
            SET status = 'declined', response_code = $2, updated_at = NOW()
            WHERE uuid = $1
          SQL
        end
      end
    end
  end
end
