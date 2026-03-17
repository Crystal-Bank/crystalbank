module CrystalBank::Types::LedgerTransactions
  enum Direction
    DEBIT
    CREDIT

    def to_s
      super.to_s.downcase
    end
  end

  enum EntryType
    PRINCIPAL
    SETTLEMENT
    TRANSACTION_FEE
    # Accruals & Interest
    INTEREST
    ACCRUED_INTEREST
    PENALTY_INTEREST
    # Fees & Charges
    OVERDRAFT_FEE
    MAINTENANCE_FEE
    COMMISSION
    FOREIGN_EXCHANGE_FEE
    # FX & Valuation
    FX_GAIN
    FX_LOSS
    REVALUATION
    # Credit Events
    PENALTY
    CHARGE_OFF
    PROVISION
    # Corporate Actions
    DIVIDEND
    PREMIUM
    REBATE
    # Operational
    ADJUSTMENT
    REVERSAL
    COLLATERAL
    ESCROW

    def to_s
      super.to_s.downcase
    end
  end
end
