require 'singleton'

class Simulator
  include Singleton

  attr_accessor :position, :pin_sleep, :pin_enable, :pin_ms1, :pin_ms2, :pin_ms3, :pin_dir, :pin_reset

  def initialize
    @position = 0

#    @pin_sleep =	:low
    @pin_sleep =	:high
#    @pin_enable =	:high
    @pin_enable =	:low
    @pin_step =		:low
    @pin_ms1 =		:low
    @pin_ms2 =		:low
    @pin_ms3 =		:low
    @pin_dir =		:low
    @pin_reset =	:high
  end

  def resolution
    if @pin_ms1 == :low \
      and @pin_ms2 == :low \
      and @pin_ms3 == :low
    then
      return 1
    elsif @pin_ms1 == :high \
      and @pin_ms2 == :low \
      and @pin_ms3 == :low
    then
      return 2
    elsif @pin_ms1 == :low \
      and @pin_ms2 == :high \
      and @pin_ms3 == :low
    then
      return 4
    elsif @pin_ms1 == :high \
      and @pin_ms2 == :high \
      and @pin_ms3 == :low
    then
      return 8
    elsif @pin_ms1 == :high \
      and @pin_ms2 == :high \
      and @pin_ms3 == :high
    then
      return 16
    else
      return false
    end
  end

  def pin_step=(state)
    if (@pin_enable == :low) \
      and (@pin_sleep == :high) \
      and (@pin_reset == :high) \
      and (@pin_step == :low) \
      and (state == :high)
    then
      if @pin_dir == :high
        @position += Rational(1, self.resolution)
      else
        @position -= Rational(1, self.resolution)
      end
    end
    @pin_step = state
  end
end
