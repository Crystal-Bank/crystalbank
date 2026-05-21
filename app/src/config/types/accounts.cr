module CrystalBank::Types::Accounts
  INTERNAL_TYPES = ["settlement", "nostro", "cpd", "frozen_funds"]

  enum Type
    # Public account types
    Checking
    Overnight_Money
    Savings
    Card

    # Internal account types (ledger use only)
    Settlement
    Nostro
    CPD
    Frozen_Funds

    def to_s
      super.to_s.downcase
    end

    def internal?
      CrystalBank::Types::Accounts::INTERNAL_TYPES.includes?(to_s)
    end
  end
end
