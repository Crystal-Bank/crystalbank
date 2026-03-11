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

    def to_s
      super.to_s.downcase
    end
  end
end
