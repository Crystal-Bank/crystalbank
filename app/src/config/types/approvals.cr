module CrystalBank::Types::Approvals
  enum Status
    Pending
    Completed
    Rejected

    def to_s
      super.to_s.downcase
    end
  end
end
