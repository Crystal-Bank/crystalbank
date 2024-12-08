module CrystalBank
  module Exception
    class Authentication < ES::Exception::Error
      def initialize(message = "Authentication error", status_code : HTTP::Status = HTTP::Status::BAD_REQUEST)
        super(message, print_backtrace: true, status_code: status_code, type: self.class.to_s)
      end
    end
  end
end
