module CrystalBank::Domains::Approvals
  struct ApprovalSubject
    include JSON::Serializable

    struct Field
      include JSON::Serializable

      getter label : String
      getter value : String

      def initialize(@label : String, @value : String); end
    end

    getter title : String
    getter summary : String
    getter fields : Array(Field)

    def initialize(@title : String, @summary : String, @fields : Array(Field)); end
  end
end
