module CrystalBank
  module Exception
    class InvalidContext < ES::Exception::Error
      def initialize(message = "Invalid context error", status_code : HTTP::Status = HTTP::Status::INTERNAL_SERVER_ERROR)
        super(message, print_backtrace: true, status_code: status_code, type: self.class.to_s)
      end
    end
  end
end
