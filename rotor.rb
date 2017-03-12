unless $simulate
require 'rpi_gpio'
end # simulate
require 'singleton'

require_relative 'stepper.rb'
require_relative 'angle.rb'

class Rotor
  include Singleton

  attr_accessor :error,
                :step_pause,
                :step_queue,
                :position,
                :motor_steps,
                :motor_max_resolution,
                :min_rad,
                :max_rad

  PIN_POSITIVE_SENSOR =	22

  def initialize
    @error = Array.new

    @step_pause = 0.1

    @motor_steps = 400
    @motor_max_resolution = 16

    # FIXME! check that positions are within range on assignment
    # position at which the negative sensor is closed
    @negative_sensor_position = -15
    # position at which the postive sensor is closed
    @positive_sensor_position = 15
    # position at which to rotate after finding a limit sensor
    @reset_position = 0

    # FIXME! check that range is possible on assignment
    # Clockwise, relative to vessel's forward direction
    @min_rad = -Math::PI
    @max_rad = Math::PI

    unless $simulate
    RPi::GPIO.set_numbering :bcm

    RPi::GPIO.setup PIN_MAX_SENSOR, :as => :input
    end # simulate

    @position = 0
    @step_queue = 0
    self.reset
  end

  def range
    if (@max_rad - @min_rad >= 2 * Math::PI)
      return (-Float::INFINITY..Float::INFINITY)
    else
      return (Angle::coterminal(@min_rad, 2 * Math::PI, @min_rad, 1)..Angle::coterminal(@max_rad, 2 * Math::PI, @max_rad, 1))
    end
  end

  def throw
    @max_rad - @min_rad
  end

  # does not adjust @position or wait; literally just step no matter what
  def step_forward
    puts "Step forward"
    Stepper.instance.set_dir :high
    Stepper.instance.set_step :high
    Stepper.instance.set_step :low
  end

  # does not adjust @position; literally just step no matter what
  def step_backward
    puts "Step backward"
    Stepper.instance.set_dir :low
    Stepper.instance.set_step :high
    Stepper.instance.set_step :low
  end

  def next_in_queue
    if self.step_queue > 0
      if self.step_queue >= 1
        resolution = 1
      elsif self.step_queue >= 0.5
        resolution = 2
      elsif self.step_queue >= 0.25
        resolution = 4
      elsif self.step_queue >= 0.125
        resolution = 8
      elsif self.step_queue >= 0.0625
        resolution = 16
      else
        puts "Too precise!"
        return false
      end
      Stepper.instance.set_resolution(resolution)
      self.step_forward
      self.step_queue -= Rational(1, resolution)
    elsif self.step_queue < 0
      if self.step_queue <= 1
        resolution = 1
      elsif self.step_queue <= 0.5
        resolution = 2
      elsif self.step_queue <= 0.25
        resolution = 4
      elsif self.step_queue <= 0.125
       resolution = 8
      elsif self.step_queue <= 0.0625
        resolution = 16
      else
        puts "Too precise!"
        return false
      end
      Stepper.instance.set_resolution(resolution)
      self.step_backward
      self.step_queue += Rational(1, resolution)
    end
  end

  def flush_queue
    while self.step_queue != 0
      if self.next_in_queue == false
        return false
      end
      sleep @step_pause
    end
    return true
  end

  def step_backward_until
    steps = 0
    until yield or (steps >= Angle::convert(self.throw, 2 * Math::PI, @motor_steps))
      steps += 1
      @step_queue -= 1
      self.flush_queue
    end

    if steps >= (self.throw / (2 * Math::PI)) * @motor_steps
      # We've stepped the whole throw of the rotor,
      # even if we started at one end of the range, we'd have reached the other
      puts "We're never gonna get there!"
      @error << :sensor_failure
      return false
    else
      puts "It's true!"
    end
  end

  def step_forward_until
    steps = 0
    until yield or (steps >= Angle::convert(self.throw, 2 * Math::PI, @motor_steps))
      steps += 1
      @step_queue += 1
      self.flush_queue
    end

    if steps >= Angle::convert(self.throw, 2 * Math::PI, @motor_steps)
      # We've stepped the whole throw of the rotor,
      # even if we started at one end of the range, we'd have reached the other
      puts "We're never gonna get there!"
      @error << :sensor_failure
      return false
    else
      puts "It's true!"
      return true
    end
  end

  def step(resolution, steps)
    @step_queue += Rational(steps, resolution)
    @position += steps
  end

  def positive_sensor?
    if $simulate
    if @times.nil?
      @times = 0
    end
    if @times < 15
      @times += 1
      return false
    else
      @times = 0
      return true
    end
    else # simulate
    if RPi::GPIO.high? PIN_POSITIVE_SENSOR
      return true
    else
      return false
    end
    end # simulate
  end

  def negative_sensor?
    if $simulate
    if @times.nil?
      @times = 0
    end
    if @times < 15
      @times += 1
      return false
    else
      @times = 0
      return true
    end
    else # simulate
    if RPi::GPIO.high? PIN_NEGATIVE_SENSOR
      return true
    else
      return false
    end
    end # simulate
  end

  def reset
    if self.negative_sensor? or !self.positive_sensor?
      if !self.step_forward_until {self.positive_sensor?}
        return false
      end
      @position = @positive_sensor_position
      self.step(1, -@positive_sensor_position + @reset_position)
    else
      if !self.step_backward_until {self.negative_sensor?}
        return false
      end
      @position = @negative_sensor_position
      self.step(1, -@negative_sensor_position + @reset_position)
    end
    @position = @reset_position
  end

  def to_position(position)
    if (position % Rational(1, @motor_max_resolution)) != 0
      # given position cannot be precisely reached
      return false
    end

    rad = Angle::convert(position, @motor_steps, Math::PI * 2)
    negative_rad = Angle::coterminal(rad, 2 * Math::PI, -1, 1)
    positive_rad = Angle::coterminal(rad, 2 * Math::PI, 1, 1)
    unless self.range.include?(negative_rad) or self.range.include?(positive_rad)
      # given position cannot be reached
      return false
    end

    # FIXME! go to closest position
    step(1, Angle::coterminal(position, @motor_steps, 1, 1) - @position)
  end

  def to_relative_bearing(bearing)
    to_position(Angle::convert(bearing, 360, @motor_steps))
  end
end
