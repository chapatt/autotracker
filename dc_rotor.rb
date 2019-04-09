require_relative 'rotor.rb'
require_relative 'dc_motor.rb'
require_relative 'encoder.rb'
require_relative 'home_sensor.rb'

class DCRotor < Rotor
  attr_reader :aperture

  def initialize
    super

    @motor = DCMotor.instance
    @encoder = Encoder.instance
  end

  def to_position position
    super

    if @encoder.position < position
      @encoder.direction = :clockwise
      @encoder.call_at(position) { @motor.stop_cw; false }
      @motor.start_cw
    elsif @encoder.position > position
      @encoder.direction = :counterclockwise
      @encoder.call_at(position) { @motor.stop_ccw; false }
      @motor.start_ccw
    end
  end

  def position
    @encoder.position
  end
end
