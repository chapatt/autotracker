module Angle
  def self.angleCoterminalWith angle, inTurn:, withBase: 360
    if (positive_in_first_turn = angle.remainder(withBase)) < 0
      positive_in_first_turn += withBase
    end

    if inTurn.positive?
      return positive_in_first_turn + ((inTurn.abs - 1) * withBase)
    else
      return (positive_in_first_turn - withBase) - ((inTurn.abs - 1) * withBase)
    end
  end

  def self.angleClosestTo angle, coterminalWith:, base: 360
    turn = Angle::turnContaining angle, base: base
    same_turn = Angle::angleCoterminalWith coterminalWith, inTurn: turn, withBase: base
    difference = same_turn - angle
    if difference.abs > 180
      if difference.positive?
        return Angle::angleCoterminalWith coterminalWith, inTurn: Angle::turnPreviousTo(turn), withBase: base
      else
        return Angle::angleCoterminalWith coterminalWith, inTurn: Angle::turnFollowing(turn), withBase: base
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

  def self.turnContaining angle, base: 360
    sign = angle.negative? ? -1 : 1
    sign * (angle.abs / base.to_f).ceil
  end

  def self.convert angle, from_base:, to_base:
    return Rational(angle, from_base) * to_base
  end
end
