module CrystalBank::Types::Accounts
  enum BlockType
    ComplianceBlock
    OperationsBlock
    GenericDebitBlock
    GenericCreditBlock
    GenericFullBlock

    def effect : BlockEffect
      case self
      when ComplianceBlock, GenericFullBlock
        BlockEffect::Full
      when OperationsBlock, GenericDebitBlock
        BlockEffect::Debit
      when GenericCreditBlock
        BlockEffect::Credit
      else
        raise "Unhandled block type: #{self}"
      end
    end

    def to_s
      super.to_s.downcase
    end
  end

  enum BlockEffect
    Full
    Debit
    Credit
  end

  enum EffectiveBlock
    FullBlock
    DebitBlock
    CreditBlock
    None

    def self.evaluate(active_blocks : Array(BlockType)) : EffectiveBlock
      return None if active_blocks.empty?

      effects = active_blocks.map(&.effect).uniq

      return FullBlock if effects.includes?(BlockEffect::Full)
      return FullBlock if effects.includes?(BlockEffect::Debit) && effects.includes?(BlockEffect::Credit)
      return DebitBlock if effects.includes?(BlockEffect::Debit)
      return CreditBlock if effects.includes?(BlockEffect::Credit)

      None
    end

    def to_s
      super.to_s.downcase
    end
  end
end
