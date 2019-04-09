unless $simulate
require 'rpi_gpio'
end # unless $simulate
require 'singleton'

require_relative 'stepper.rb'

require_relative 'core_extensions/numeric/angle.rb'
Numeric.include CoreExtensions::Numeric::Angle

require_relative 'core_extensions/numeric/steps.rb'
Numeric.include CoreExtensions::Numeric::Steps

class StepperRotor
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

    # FIXME! rename @rotor_steps
    @motor_steps = 200
    @motor_max_resolution = 16

    # FIXME! check that positions are within range on assignment
    # position at which the negative sensor is closed
    @negative_sensor_position = -Math::PI / 2
    # position at which the postive sensor is closed
    @positive_sensor_position = Math::PI / 2
    # position at which to rotate after finding a limit sensor
    @reset_position = 0

    # FIXME! check that range is possible on assignment
    # Clockwise, relative to vessel's forward direction
    @min_rad = -Math::PI - 1
    @max_rad = Math::PI + 1

    unless $simulate
    RPi::GPIO.set_numbering :bcm

    RPi::GPIO.setup PIN_MAX_SENSOR, :as => :input
    end # unless $simulate

    # actual current position is @position - @step_queue
    @position = 0
    @step_queue = 0
    self.reset
  end

  def range
    return (@min_rad..@max_rad)
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
      elsif self.step_queue >= Rational(1, 2)
        resolution = 2
      elsif self.step_queue >= Rational(1, 4)
        resolution = 4
      elsif self.step_queue >= Rational(1, 8)
        resolution = 8
      elsif self.step_queue >= Rational(1, 16)
        resolution = 16
      else
        puts "Too precise!"
        return false
      end
      Stepper.instance.set_resolution(resolution)
      puts "Resolution: #{resolution}"
      self.step_forward
      puts "Queue before step: #{self.step_queue}"
      self.step_queue -= Rational(1, resolution)
      puts "Queue after step: #{self.step_queue}"
    elsif self.step_queue < 0
      if self.step_queue <= -1
        resolution = 1
      elsif self.step_queue <= -Rational(1, 2)
        resolution = 2
      elsif self.step_queue <= -Rational(1, 4)
        resolution = 4
      elsif self.step_queue <= -Rational(1, 8)
       resolution = 8
      elsif self.step_queue <= -Rational(1, 16)
        resolution = 16
      else
        puts "Too precise!"
        return false
      end
      Stepper.instance.set_resolution(resolution)
      puts "Resolution: #{resolution}"
      self.step_backward
      puts "Queue before step: #{self.step_queue}"
      self.step_queue += Rational(1, resolution)
      puts "Queue after step: #{self.step_queue}"
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
    until yield or (steps >= self.throw.convert(2 * Math::PI, @motor_steps))
      steps += 1
      @step_queue -= 1
      self.flush_queue
    end

    if steps >= self.throw.convert(2 * Math::PI, @motor_steps)
      # We've stepped the whole throw of the rotor;
      # even if we started at one end of the range, we'd have reached the other end
      puts "We're never gonna get there!"
      @error << :sensor_fault
      return false
    else
      puts "It's true!"
    end
  end

  def step_forward_until
    steps = 0
    until yield or (steps >= self.throw.convert(2 * Math::PI, @motor_steps))
      steps += 1
      @step_queue += 1
      self.flush_queue
    end

    if steps >= self.throw.convert(2 * Math::PI, @motor_steps)
      # We've stepped the whole throw of the rotor,
      # even if we started at one end of the range, we'd have reached the other
      puts "We're never gonna get there!"
      @error << :sensor_fault
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
    if @times < @positive_sensor_position.abs.convert(2 * Math::PI, @motor_steps) + 2
      @times += 1
      return false
    else
      @times = 0
      return true
    end
    else # if $simulate
    if RPi::GPIO.high? PIN_POSITIVE_SENSOR
      return true
    else
      return false
    end
    end # if $simulate
  end

  def negative_sensor?
    if $simulate
    if @times.nil?
      @times = 0
    end
    if @times < @negative_sensor_position.abs.convert(2 * Math::PI, @motor_steps) + 2
      @times += 1
      return false
    else
      @times = 0
      return true
    end
    else # if $simulate
    if RPi::GPIO.high? PIN_NEGATIVE_SENSOR
      return true
    else
      return false
    end
    end # if $simulate
  end

  def reset
    if self.negative_sensor? or !self.positive_sensor?
      if !self.step_forward_until {self.positive_sensor?}
        return false
      end
      @position = @positive_sensor_position.convert(2 * Math::PI, @motor_steps).round_to_resolution(@motor_max_resolution)
    else
      if !self.step_backward_until {self.negative_sensor?}
        return false
      end
      @position = @negative_sensor_position.convert(2 * Math::PI, @motor_steps).round_to_resolution(@motor_max_resolution)
    end
    self.to_position(@reset_position)
  end

  def to_position(position)
    puts "You're telling me to go to #{position}?!"

    rad = position.convert(@motor_steps, Math::PI * 2)
    unless self.range.include?(rad)
      puts "the given position cannot be reached"
      return false
    end

    if (position % Rational(1, @motor_max_resolution)) != 0
      puts "the given position cannot be precisely reached"
      return false
    end

    step(1, position - @position)
  end

  # TODO: Rotate smallest angle to reach bearing
  # Convert bearing to positive radians coterminal in first turn
  # Convert @position to positive radians coterminal in first turn
  # Subtract position_prime from bearing_prime
  # If the sum of position_rad and the difference is in range, call to_position with sum
  #  else if sum is greater than @max_rad, call to_position with sum - 2PI
  #  else if sum is less than @min_rad, call to_position with sum + 2PI
  def to_relative_bearing(bearing)
    position_rad = @position.convert(@motor_steps, 2 * Math::PI)
    difference = bearing.coterminal(2 * Math::PI, 1, 1) - position_rad.coterminal(2 * Math::PI, 1, 1)
    closest_position = position_rad + difference
    if self.range.include? closest_position
      go_to_position = closest_position.convert(2 * Math::PI, @motor_steps)
      rounded = go_to_position.round_to_resolution(@motor_max_resolution)
      to_position(rounded)
    elsif (closest_position > @max_rad) \
      and (self.range.include? (less = closest_position - (2 * Math::PI)))
    then
      go_to_position = less.convert(2 * Math::PI, @motor_steps)
      rounded = go_to_position.round_to_resolution(@motor_max_resolution)
      to_position(rounded)
    elsif (closest_position < @min_rad) \
      and (self.range.include? (more = closest_position + (2 * Math::PI)))
    then
      go_to_position = more.convert(2 * Math::PI, @motor_steps)
      rounded = go_to_position.round_to_resolution(@motor_max_resolution)
      to_position(rounded)
    else
      puts "the given bearing cannot be reached"
      return false
    end
  end
end
