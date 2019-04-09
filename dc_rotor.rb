require_relative 'rotor.rb'
require_relative 'dc_motor.rb'
require_relative 'encoder.rb'
require_relative 'home_sensor.rb'

class DCRotor < Rotor
  def initialize
    super

    @motor = DCMotor.instance
    @encoder = Encoder.instance
  end

  def to_rel_bearing rel_bearing
    super

    if @encoder.position < rel_bearing
      @encoder.direction = :clockwise
      @encoder.call_at(rel_bearing) { @motor.stop_cw; false }
      @motor.start_cw
    elsif @encoder.position > rel_bearing
      @encoder.direction = :counterclockwise
      @encoder.call_at(rel_bearing) { @motor.stop_ccw; false }
      @motor.start_ccw
    end
  end

  def rel_bearing
    @encoder.position
  end
end
