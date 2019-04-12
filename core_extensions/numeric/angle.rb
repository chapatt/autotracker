module CoreExtensions
  module Numeric
    module Angle
      def coterminalInTurn turn, withBase: 360
        if (positive_in_first_turn = self.remainder(withBase)) < 0
          positive_in_first_turn += withBase
        end
    
        if turn.positive?
          return positive_in_first_turn + ((turn.abs - 1) * withBase)
        else
          return (positive_in_first_turn - withBase) - ((turn.abs - 1) * withBase)
        end
      end
    
      def coterminalClosestTo angle, withBase: 360
        turn = angle.turn withBase: base
        same_turn = self.coterminalInTurn turn, withBase: withBase
        difference = same_turn - angle
        if difference.abs > withBase / 2
          if difference.positive?
            return self.cotermianlInTurn self.class.turnPreviousTo(turn), withBase: withBase
          else
            return self.coterminalInTurn self.class.turnFollowing(turn), withBase: withBase
          end
        else
          return same_turn
        end
      end
    
      def self.turnPreviousTo turn
        if turn == 1
          return -1
        else
          return turn - 1
        end
      end
    
      def self.turnFollowing turn
        if turn == -1
          return 1
        else
          return turn + 1
        end
      end
    
      def turn withBase: 360
        sign = self.negative? ? -1 : 1
        sign * (self.abs / withBase.to_f).ceil
      end
    
      def convertFromBase from_base, to_base:
        return Rational(self, from_base) * to_base
      end
    end
  end
end
