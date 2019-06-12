require_relative 'gpio'
require 'singleton'

class DCMotor
  include Singleton

  PIN_CW =       16
  PIN_CCW =       6
  PIN_HBRIDGE1 = 22
  PIN_HBRIDGE2 = 23
  PIN_EN =       12

  def initialize
    GPIO::setup PIN_CW, GPIO::TYPE_GPIO, { :direction => GPIO::DIRECTION_OUTPUT, :active_low => true }
    GPIO::set_state PIN_CW, GPIO::STATE_LOW
    GPIO::setup PIN_CCW, GPIO::TYPE_GPIO, { :direction => GPIO::DIRECTION_OUTPUT, :active_low => true }
    GPIO::set_state PIN_CCW, GPIO::STATE_LOW
    GPIO::setup PIN_EN, GPIO::TYPE_GPIO, { :direction => GPIO::DIRECTION_OUTPUT }
    GPIO::set_state PIN_EN, GPIO::STATE_LOW
    GPIO::setup PIN_HBRIDGE1, GPIO::TYPE_GPIO, { :direction => GPIO::DIRECTION_OUTPUT }
    GPIO::set_state PIN_HBRIDGE1, GPIO::STATE_LOW
    GPIO::setup PIN_HBRIDGE2, GPIO::TYPE_GPIO, { :direction => GPIO::DIRECTION_OUTPUT }
    GPIO::set_state PIN_HBRIDGE2, GPIO::STATE_HIGH

    ObjectSpace.define_finalizer(self, proc {
      GPIO::cleanup PIN_CW
      GPIO::cleanup PIN_CCW
      GPIO::cleanup PIN_EN
      GPIO::cleanup PIN_HBRIDGE1
      GPIO::cleanup PIN_HBRIDGE2
    })
  end

  def start_cw
    GPIO::set_state PIN_EN, GPIO::STATE_HIGH
    GPIO::set_state PIN_CW, GPIO::STATE_HIGH
  end

  def start_ccw
    GPIO::set_state PIN_EN, GPIO::STATE_HIGH
    GPIO::set_state PIN_CCW, GPIO::STATE_HIGH
  end

  def stop_cw
    GPIO::set_state PIN_EN, GPIO::STATE_LOW
    GPIO::set_state PIN_CW, GPIO::STATE_LOW
  end

  def stop_ccw
    GPIO::set_state PIN_EN, GPIO::STATE_LOW
    GPIO::set_state PIN_CCW, GPIO::STATE_LOW
  end
end
