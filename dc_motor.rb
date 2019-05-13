require_relative 'gpio'
require 'singleton'

class DCMotor
  include Singleton

  PIN_CW =  16
  PIN_CCW = 26

  def initialize
    GPIO::setup PIN_CW, :TYPE_GPIO, { :direction => GPIO::DIRECTION_OUTPUT, :active_low => true }
    GPIO::set_state PIN_CW, GPIO::STATE_LOW
    GPIO::setup PIN_CCW, :TYPE_GPIO, { :direction => GPIO::DIRECTION_OUTPUT, :active_low => true }
    GPIO::set_state PIN_CCW, GPIO::STATE_LOW

    ObjectSpace.define_finalizer(self, proc {
      GPIO::cleanup PIN_CW
      GPIO::cleanup PIN_CCW
    })
  end

  def start_cw
    GPIO::set_state PIN_CW, GPIO::STATE_HIGH
  end

  def start_ccw
    GPIO::set_state PIN_CCW, GPIO::STATE_HIGH
  end

  def stop_cw
    GPIO::set_state PIN_CW, GPIO::STATE_LOW
  end

  def stop_ccw
    GPIO::set_state PIN_CCW, GPIO::STATE_LOW
  end
end
