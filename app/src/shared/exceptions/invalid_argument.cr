module CrystalBank
  module Exception
    class InvalidArgument < ES::Exception::Error
      def initialize(message = "Invalid argument error", status_code : HTTP::Status = HTTP::Status::BAD_REQUEST)
        super(message, print_backtrace: true, status_code: status_code, type: self.class.to_s)
      end
    end
  end
end
