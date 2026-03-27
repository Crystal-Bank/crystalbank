module CrystalBank::Types::Accounts
  enum BlockType
    COMPLIANCE_BLOCK
    OPERATIONS_BLOCK
    GENERIC_DEBIT_BLOCK
    GENERIC_CREDIT_BLOCK
    GENERIC_FULL_BLOCK

    def effect : BlockEffect
      case self
      when COMPLIANCE_BLOCK, GENERIC_FULL_BLOCK
        BlockEffect::FULL
      when OPERATIONS_BLOCK, GENERIC_DEBIT_BLOCK
        BlockEffect::DEBIT
      when GENERIC_CREDIT_BLOCK
        BlockEffect::CREDIT
      else
        raise "Unhandled block type: #{self}"
      end
    end

    def to_s
      super.to_s.downcase
    end
  end

  enum BlockEffect
    FULL
    DEBIT
    CREDIT
  end

  enum EffectiveBlock
    FULL_BLOCK
    DEBIT_BLOCK
    CREDIT_BLOCK
    NONE

    def self.evaluate(active_blocks : Array(BlockType)) : EffectiveBlock
      return NONE if active_blocks.empty?

      effects = active_blocks.map(&.effect).uniq

      return FULL_BLOCK if effects.includes?(BlockEffect::FULL)
      return FULL_BLOCK if effects.includes?(BlockEffect::DEBIT) && effects.includes?(BlockEffect::CREDIT)
      return DEBIT_BLOCK if effects.includes?(BlockEffect::DEBIT)
      return CREDIT_BLOCK if effects.includes?(BlockEffect::CREDIT)

      NONE
    end

    def to_s
      super.to_s.downcase
    end
  end
end
