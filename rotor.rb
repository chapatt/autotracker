unless $simulate
require 'rpi_gpio'
end # simulate
require 'singleton'

class Rotor
  include Singleton

  attr_accessor :units_angle, :motor_steps, :motor_max_resolution, :min_rad, :max_rad

  PIN_A4988_SLEEP =	2
  PIN_A4988_ENABLE =	3
  PIN_A4988_STEP =	4
  PIN_A4988_MS1 =	14
  PIN_A4988_MS2 =	15
  PIN_A4988_MS3 =	17
  PIN_A4988_DIR =	18
  PIN_A4988_RESET =	27

  PIN_POSITIVE_SENSOR =	22

  def initialize
    @units_angle = :deg

    @motor_steps = 400
    @motor_max_resolution = 16

    # FIXME! check that positions are within range on assignment
    # position at which the negative sensor is closed
    @negative_sensor_position = 0
    # position at which the postive sensor is closed
    @positive_sensor_position = -5
    # position at which to rotate after finding a limit sensor
    @reset_position = 0

    # FIXME! check that range is possible on assignment
    # Clockwise, relative to vessel's forward direction
    @min_rad = -1.25 * Math::PI
    @max_rad = 1.25 * Math::PI

    unless $simulate
    RPi::GPIO.set_numbering :bcm

    # sleep mode
    RPi::GPIO.setup PIN_A4988_SLEEP, :as => :output, :initialize => :low

    # disabled
    RPi::GPIO.setup PIN_A4988_ENABLE, :as => :output, :initialize => :high

    RPi::GPIO.setup PIN_A4988_STEP, :as => :output, :initialize => :low

    # full step
    RPi::GPIO.setup PIN_A4988_MS1, :as => :output, :initialize => :low
    RPi::GPIO.setup PIN_A4988_MS2, :as => :output, :initialize => :low
    RPi::GPIO.setup PIN_A4988_MS3, :as => :output, :initialize => :low

    RPi::GPIO.setup PIN_A4988_DIR, :as => :output, :initialize => :low

    # not-reset
    RPi::GPIO.setup PIN_A4988_RESET, :as => :output, :initialize => :high

    RPi::GPIO.setup PIN_MAX_SENSOR, :as => :input
    end # simulate

    @position = 0
    self.reset
  end

  def range
    # FIXME! calculate range
    if @max_rad - @min_rad >= 2 * Math::PI
      return (0..@motor_steps)
    end
  end

  def set_resolution(resolution)
    case resolution
    when :full, 1
      unless $simulate
      RPi::GPIO.set_low PIN_A4988_MS1
      RPi::GPIO.set_low PIN_A4988_MS2
      RPi::GPIO.set_low PIN_A4988_MS3
      end # simulate
      return true
    when :half, 2
      unless $simulate
      RPi::GPIO.set_high PIN_A4988_MS1
      RPi::GPIO.set_low PIN_A4988_MS2
      RPi::GPIO.set_low PIN_A4988_MS3
      end # simulate
      return true
    when :quarter, 4
      unless $simulate
      RPi::GPIO.set_low PIN_A4988_MS1
      RPi::GPIO.set_high PIN_A4988_MS2
      RPi::GPIO.set_low PIN_A4988_MS3
      end # simulate
      return true
    when :eighth, 8
      unless $simulate
      RPi::GPIO.set_high PIN_A4988_MS1
      RPi::GPIO.set_high PIN_A4988_MS2
      RPi::GPIO.set_low PIN_A4988_MS3
      end # simulate
      return true
    when :sixteenth, 16
      unless $simulate
      RPi::GPIO.set_high PIN_A4988_MS1
      RPi::GPIO.set_high PIN_A4988_MS2
      RPi::GPIO.set_high PIN_A4988_MS3
      end # simulate
      return true
    else
      return false
    end
  end

  def to_relative_bearing(bearing)
    #to_position()
  end

  def to_position(position)
    if (position % Rational(1, @motor_max_resolution)) != 0
      # given position cannot be precisely reached
      return false
    end

    # FIXME! this is wrong
    if !self.range.include?(position % @motor_steps)
      # given position cannot be reached
      return false
    end

    step(16, 5)
  end

  def step(resolution, steps)
    self.set_resolution(resolution)
    # actually step here
    if steps < 0
      steps.times {step_backward}
    else
      steps.times {step_forward}
    end
    puts "Taking #{steps} steps!"
    @position += steps
  end

  # does not adjust @position; literally just step no matter what
  def step_forward
    unless $simulate
    RPi::GPIO.set_high PIN_A4988_DIR
    RPi::GPIO.set_high PIN_A4988_STEP
    RPi::GPIO.set_low PIN_A4988_STEP
    end # simulate
  end

  # does not adjust @position; literally just step no matter what
  def step_backward
    unless $simulate
    RPi::GPIO.set_low PIN_A4988_DIR
    RPi::GPIO.set_high PIN_A4988_STEP
    RPi::GPIO.set_low PIN_A4988_STEP
    end # simulate
  end

  def step_forward_until
    until yield
      step_forward
      puts "One small step..."
    end

    puts "It's true!"
  end

  def reset
    if self.negative_sensor? or !self.positive_sensor?
      self.step_forward_until {self.positive_sensor?}
      self.step(:full, -@positive_sensor_position + @reset_position)
    else
      self.step_backward_until {self.negative_sensor?}
      self.step(:full, -@negative_sensor_position + @reset_position)
    end
    @position = @reset_position
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
end
