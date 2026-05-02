module CrystalBank::Domains::Approvals
  struct ApprovalContext
    include JSON::Serializable

    struct Field
      include JSON::Serializable

      getter label : String
      getter value : String

      def initialize(@label : String, @value : String); end
    end

    # Short label shown as the type badge in the table row (e.g. "SEPA Credit Transfer")
    getter title : String

    # One-liner shown next to the badge in the table row (e.g. "50.00 EUR → DE89... (Acme GmbH)")
    getter summary : String

    # Label/value pairs rendered in the detail drawer
    getter fields : Array(Field)

    def initialize(@title : String, @summary : String, @fields : Array(Field)); end
  end
end
