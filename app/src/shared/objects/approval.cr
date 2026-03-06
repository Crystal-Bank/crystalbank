module CrystalBank
  module Objects
    # Represents a single required approval step.
    #
    # Each step defines one or more permissions, any of which satisfies the step.
    # An approval chain is expressed as an Array(Approval) — every element in the
    # array must be independently satisfied (in order) before the underlying
    # action is accepted.
    #
    # Examples
    # --------
    # Two independent eyes, both with the same permission:
    #   [Approval.new([APPROVE_accounts_opening_request]),
    #    Approval.new([APPROVE_accounts_opening_request])]
    #
    # One approval accepted from either of two permissions:
    #   [Approval.new([APPROVE_accounts_opening_request,
    #                  APPROVE_accounts_opening_request_for_high_net_worth_clients])]
    struct Approval
      include JSON::Serializable

      getter required_permissions : Array(CrystalBank::Permissions)

      def initialize(@required_permissions : Array(CrystalBank::Permissions))
      end

      # Returns true when at least one of *actor_permissions* covers this step.
      def satisfied_by?(actor_permissions : Array(CrystalBank::Permissions)) : Bool
        required_permissions.any? { |p| actor_permissions.includes?(p) }
      end
    end
  end
end
