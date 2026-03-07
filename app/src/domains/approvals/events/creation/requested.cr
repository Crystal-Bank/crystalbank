module CrystalBank::Domains::Approvals
  module Creation
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "Approval", "approval.creation.requested" do
          attribute :scope_id, UUID
          attribute :source_aggregate_type, String
          attribute :source_aggregate_id, UUID
          attribute :required_approvals, Array(String)
          attribute :requestor_id, UUID?
        end
      end
    end
  end
end
