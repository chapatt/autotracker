module Angle
  def self.coterminal(angle, base, direction, turn)
    if (positive_in_first_turn = angle.remainder(base)) < 0
      positive_in_first_turn += base
    end

    if direction > 0
      return positive_in_first_turn + ((turn - 1) * base)
    elsif direction < 0
      return (positive_in_first_turn - base) - ((turn - 1) * base)
    else
      return false
    end
  end

  def self.convert(angle, from_base, to_base)
    return Rational(angle, from_base) * to_base
  end
end
