module CrystalBank
  module Validators
    module Iban
      # Validates an IBAN string using the ISO 13616 MOD-97 checksum algorithm.
      # Returns true only when the IBAN is structurally well-formed AND the
      # check digits are correct (remainder of the numeric expansion mod 97 == 1).
      def self.valid?(iban : String) : Bool
        # 1. Normalise: strip whitespace, uppercase
        s = iban.gsub(/\s/, "").upcase

        # 2. Structural check
        #    - Overall length: 15 (shortest IBAN) to 34 (longest defined)
        #    - Characters 0-1: country code — two ASCII letters
        #    - Characters 2-3: check digits — two ASCII digits
        #    - Characters 4+: BBAN — ASCII letters and digits only
        return false unless s.size.in?(15..34)
        return false unless s[0, 2].chars.all?(&.ascii_uppercase?)
        return false unless s[2, 2].chars.all?(&.ascii_number?)
        return false unless s[4..].chars.all? { |c| c.ascii_uppercase? || c.ascii_number? }

        # 3. Rearrange: move the first 4 characters to the end
        rearranged = s[4..] + s[0, 4]

        # 4. Replace each letter with its numeric value (A=10 … Z=35)
        numeric_str = String.build do |sb|
          rearranged.each_char do |c|
            if c.ascii_number?
              sb << c
            else
              sb << (c.ord - 'A'.ord + 10)
            end
          end
        end

        # 5. Compute numeric_str MOD 97 by processing in chunks to avoid overflow
        remainder = 0
        numeric_str.each_char do |c|
          remainder = (remainder * 10 + c.to_i) % 97
        end

        remainder == 1
      end
    end
  end
end
