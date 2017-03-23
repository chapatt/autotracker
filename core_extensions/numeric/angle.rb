module CoreExtensions
  module Numeric
    module Angle
      def coterminal(base, direction, turn)
        if (positive_in_first_turn = self.remainder(base)) < 0
          positive_in_first_turn += base
        end

        if direction >= 0
          return positive_in_first_turn + ((turn - 1) * base)
        else
          return (positive_in_first_turn - base) - ((turn - 1) * base)
        end
      end

      def convert(from_base, to_base)
        return Rational(self, from_base) * to_base
      end
    end
  end
end
