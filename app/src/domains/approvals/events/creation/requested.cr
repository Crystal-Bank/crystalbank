module CrystalBank::Domains::Approvals
  module Creation
    module Events
      class Requested < ES::Event
        include ::ES::EventDSL

        define_event "Approval", "approval.creation.requested" do
          # The aggregate (e.g. account) that is waiting for these approvals
          attribute :reference_aggregate_id, UUID
          # Human-readable key that identifies the action type, e.g. "accounts.opening"
          attribute :reference_type, String
          attribute :scope_id, UUID
          # Serialised Array(CrystalBank::Objects::Approval)
          attribute :required_approvals, Array(CrystalBank::Objects::Approval)
        end
      end
    end
  end
end
