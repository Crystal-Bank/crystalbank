module CrystalBank::Domains::Cards::Iso8583::V1993::Advices
  module Projections
    class Advices < ES::Projection
      define_projection "projections.iso8583_v1993_advices", init: true do
        column :id,                        Int32,  serial: true, primary_key: true
        column :uuid,                      UUID,   null: false
        column :stan,                      String, null: false
        column :pan_masked,                String, null: false
        column :amount,                    Int64,  null: false
        column :currency,                  String, null: false
        column :terminal_id,               String, null: false
        column :merchant_id,               String, null: false
        column :original_data_elements,    String
        column :replacement_amounts,       String
        column :original_authorization_id, UUID
        column :scope_id,                  UUID,   null: false
        column :response_code,             String
        column :status,                    String, null: false, default: "pending"
        column :created_at,                Time,   null: false
        column :updated_at,                Time,   null: false

        index [:uuid],    unique: true
        index [:stan]
        index [:scope_id]
      end

      apply(V1993::Advices::Advice::Events::Received) do |event|
        @projection_database.transaction do |tx|
          tx.exec(<<-SQL, event.header.aggregate_id, event.stan, event.pan_masked,
            INSERT INTO projections.iso8583_v1993_advices
              (uuid, stan, pan_masked, amount, currency, terminal_id, merchant_id,
               original_data_elements, replacement_amounts, original_authorization_id,
               scope_id, status, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'pending', NOW(), NOW())
          SQL
            event.amount, event.currency, event.terminal_id, event.merchant_id,
            event.original_data_elements, event.replacement_amounts,
            event.original_authorization_id, event.scope_id)
        end
      end

      apply(V1993::Advices::AdviceResponse::Events::Accepted) do |event|
        @projection_database.transaction do |tx|
          tx.exec(<<-SQL, event.header.aggregate_id, event.response_code)
            UPDATE projections.iso8583_v1993_advices
            SET status = 'accepted', response_code = $2, updated_at = NOW()
            WHERE uuid = $1
          SQL
        end
      end

      apply(V1993::Advices::AdviceResponse::Events::Rejected) do |event|
        @projection_database.transaction do |tx|
          tx.exec(<<-SQL, event.header.aggregate_id, event.response_code)
            UPDATE projections.iso8583_v1993_advices
            SET status = 'rejected', response_code = $2, updated_at = NOW()
            WHERE uuid = $1
          SQL
        end
      end
    end
  end
end
