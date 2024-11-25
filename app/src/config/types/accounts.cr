module CrystalBank::Types::Accounts
  enum Type
    Checking
    Overnight_Money

    def to_s
      super.to_s.downcase
    end
  end
end
