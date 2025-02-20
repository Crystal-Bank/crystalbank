module CrystalBank
  module Exception
    class Authorization < ES::Exception::Error
      def initialize(message = "Authorization error", status_code : HTTP::Status = HTTP::Status::UNAUTHORIZED)
        super(message, print_backtrace: true, status_code: status_code, type: self.class.to_s)
      end
    end
  end
end
