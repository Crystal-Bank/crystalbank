module CrystalBank::Types::Approvals
  enum Status
    Pending
    Completed

    def to_s
      super.to_s.downcase
    end
  end
end
