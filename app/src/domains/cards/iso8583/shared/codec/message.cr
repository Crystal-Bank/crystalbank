module CrystalBank::Domains::Cards::Iso8583::Shared
  # Parsed representation of an ISO 8583 message.
  record Message,
    # Four-character MTI string, e.g. "0100", "1110"
    mti : String,
    # Data element number → raw string value
    fields : Hash(Int32, String) do

    # Returns the ISO 8583 version encoded in the first MTI digit.
    #   '0' → 1987   '1' → 1993   '2' → 2003
    def version : Int32
      case mti[0]
      when '0' then 1987
      when '1' then 1993
      when '2' then 2003
      else          raise ArgumentError.new("Unknown MTI version digit: #{mti[0]}")
      end
    end

    # True when this is a request (third MTI digit is 0 or 2).
    def request? : Bool
      mti[2].in?('0', '2')
    end

    # True when this is a response (third MTI digit is 1 or 3).
    def response? : Bool
      mti[2].in?('1', '3')
    end

    # Builds the MTI for the matching response to this request.
    def response_mti : String
      raise ArgumentError.new("Message is already a response") if response?
      mti[0..1] + (mti[2].to_i + 1).to_s + mti[3]
    end
  end
end
