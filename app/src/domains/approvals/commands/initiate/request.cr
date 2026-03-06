# Base class for all domain-specific Initiate commands.
# Each subclass knows how to hydrate the originating domain aggregate
# and extract scope_id + requester_id needed to start the approval workflow.
module CrystalBank::Domains::Approvals
  module Initiate
    module Commands
      abstract class Base < ES::Command
        abstract def domain_event_handle : String

        def call
          domain_aggregate_id = @aggregate_id.as(UUID)

          scope_id, requester_id = load_scope_and_requester(domain_aggregate_id)

          rule = CrystalBank::ApprovalRules::RULES[domain_event_handle]

          approval_aggregate_id = UUID.v7

          event = Approvals::Workflow::Events::Initiated.new(
            actor_id: requester_id,
            command_handler: self.class.to_s,
            aggregate_id: approval_aggregate_id,
            domain_event_handle: domain_event_handle,
            reference_aggregate_id: domain_aggregate_id,
            scope_id: scope_id,
            requester_id: requester_id,
            approval_permission: rule.permission.to_s,
            required_approvers: rule.required_approvers
          )

          @event_store.append(event)
        end

        private abstract def load_scope_and_requester(domain_aggregate_id : UUID) : {UUID, UUID}
      end

      # Accounts
      class AccountsOpening < Base
        def domain_event_handle : String
          "account.opening.requested"
        end

        private def load_scope_and_requester(id : UUID) : {UUID, UUID}
          agg = Accounts::Aggregate.new(id)
          agg.hydrate
          {agg.state.scope_id.as(UUID), agg.state.requester_id.as(UUID)}
        end
      end

      # Customers
      class CustomersOnboarding < Base
        def domain_event_handle : String
          "customer.onboarding.requested"
        end

        private def load_scope_and_requester(id : UUID) : {UUID, UUID}
          agg = Customers::Aggregate.new(id)
          agg.hydrate
          {agg.state.scope_id.as(UUID), agg.state.requester_id.as(UUID)}
        end
      end

      # Users - Onboarding
      class UsersOnboarding < Base
        def domain_event_handle : String
          "user.onboarding.requested"
        end

        private def load_scope_and_requester(id : UUID) : {UUID, UUID}
          agg = Users::Aggregate.new(id)
          agg.hydrate
          {agg.state.scope_id.as(UUID), agg.state.requester_id.as(UUID)}
        end
      end

      # Users - Assign Roles
      class UsersAssignRoles < Base
        def domain_event_handle : String
          "user.assign_roles.requested"
        end

        private def load_scope_and_requester(id : UUID) : {UUID, UUID}
          agg = Users::Aggregate.new(id)
          agg.hydrate
          {agg.state.scope_id.as(UUID), agg.state.requester_id.as(UUID)}
        end
      end

      # Roles
      class RolesCreation < Base
        def domain_event_handle : String
          "role.creation.requested"
        end

        private def load_scope_and_requester(id : UUID) : {UUID, UUID}
          agg = Roles::Aggregate.new(id)
          agg.hydrate
          {agg.state.scope_id.as(UUID), agg.state.requester_id.as(UUID)}
        end
      end

      # Scopes
      class ScopesCreation < Base
        def domain_event_handle : String
          "scope.creation.requested"
        end

        private def load_scope_and_requester(id : UUID) : {UUID, UUID}
          agg = Scopes::Aggregate.new(id)
          agg.hydrate
          {agg.state.scope_id.as(UUID), agg.state.requester_id.as(UUID)}
        end
      end

      # Transactions - Internal Transfers
      class TransactionsInternalTransfersInitiation < Base
        def domain_event_handle : String
          "transactions.internal_transfer.initiation.requested"
        end

        private def load_scope_and_requester(id : UUID) : {UUID, UUID}
          agg = Transactions::InternalTransfers::Aggregate.new(id)
          agg.hydrate
          {agg.state.scope_id.as(UUID), agg.state.requester_id.as(UUID)}
        end
      end

      # ApiKeys - Generation
      class ApiKeysGeneration < Base
        def domain_event_handle : String
          "api_key.generation.requested"
        end

        private def load_scope_and_requester(id : UUID) : {UUID, UUID}
          agg = ApiKeys::Aggregate.new(id)
          agg.hydrate
          {agg.state.scope_id.as(UUID), agg.state.requester_id.as(UUID)}
        end
      end

      # ApiKeys - Revocation
      class ApiKeysRevocation < Base
        def domain_event_handle : String
          "api_key.revocation.requested"
        end

        private def load_scope_and_requester(id : UUID) : {UUID, UUID}
          agg = ApiKeys::Aggregate.new(id)
          agg.hydrate
          {agg.state.scope_id.as(UUID), agg.state.requester_id.as(UUID)}
        end
      end
    end
  end
end
