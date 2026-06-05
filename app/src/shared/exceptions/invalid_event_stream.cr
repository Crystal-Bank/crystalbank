module CrystalBank
  module Exception
    class InvalidEventStream < ES::Exception::Error
      def initialize(message = "Invalid event stream", status_code : HTTP::Status = HTTP::Status::UNPROCESSABLE_ENTITY)
        super(message, print_backtrace: true, status_code: status_code, type: self.class.to_s)
      end
    end
  end
end
