module CrystalBank
  module ApprovalRules
    struct Rule
      getter permission : CrystalBank::Permissions
      getter required_approvers : Int32

      def initialize(@permission : CrystalBank::Permissions, @required_approvers : Int32)
      end
    end

    # Maps each domain event handle to its approval rule.
    # required_approvers = number of distinct approvers required (n-eye principle).
    # Each approver must hold the specified permission in the scope of the original request.
    RULES = {
      "account.opening.requested"                           => Rule.new(Permissions::APPROVE_accounts_opening, 2),
      "customer.onboarding.requested"                       => Rule.new(Permissions::APPROVE_customers_onboarding, 2),
      "user.onboarding.requested"                           => Rule.new(Permissions::APPROVE_users_onboarding, 2),
      "user.assign_roles.requested"                         => Rule.new(Permissions::APPROVE_users_assign_roles, 2),
      "role.creation.requested"                             => Rule.new(Permissions::APPROVE_roles_creation, 2),
      "scope.creation.requested"                            => Rule.new(Permissions::APPROVE_scopes_creation, 2),
      "transactions.internal_transfer.initiation.requested" => Rule.new(Permissions::APPROVE_transactions_internal_transfers_initiation, 2),
      "api_key.generation.requested"                        => Rule.new(Permissions::APPROVE_api_keys_generation, 1),
      "api_key.revocation.requested"                        => Rule.new(Permissions::APPROVE_api_keys_revocation, 1),
    }
  end
end
