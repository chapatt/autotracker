require_relative 'rotor.rb'
require_relative 'dc_motor.rb'
require_relative 'encoder.rb'
require_relative 'home_sensor.rb'
require_relative 'angle.rb'

class DCRotor < Rotor
  def initialize
    super

    @motor = DCMotor.instance
    @encoder = Encoder.instance
  end

  def to_rel_bearing target_rel_bearing
    super

    target = Angle::angleClosestTo @encoder.position, coterminalWith: target_rel_bearing

    if @encoder.position < target
      @encoder.direction = :clockwise
      @encoder.call_at(target) { @motor.stop_cw; false }
      @motor.start_cw
    elsif @encoder.position > target
      @encoder.direction = :counterclockwise
      @encoder.call_at(target) { @motor.stop_ccw; false }
      @motor.start_ccw
    end
  end

  def rel_bearing
    @encoder.position
  end
end
