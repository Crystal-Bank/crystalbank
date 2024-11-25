module CrystalBank::Types::Customers
  enum Type
    Business
    Individual

    def to_s
      super.to_s.downcase
    end
  end
end
