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

  PIN_MAX_SENSOR =	22

  def initialize
    @units_angle = :deg

    @motor_steps = 400
    @motor_max_resolution = 16

    # FIXME! check that positions is within range on assignment
    @min_sensor_position = 0
    @max_sensor_position = 399
    @reset_position = 0

    # FIXME! check that range is possible on assignment
    # Clockwise, relative to vessel's forward direction
    @min_rad = -2.25 * Math::PI
    @max_rad = 2.25 * Math::PI

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

    #self.reset
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

    if !self.range.include?(position % @motor_steps)
      # given position cannot be reached
      return false
    end

    step(16, 5)
  end

  def step(resolution, steps)
    self.set_resolution(resolution)
    # actually step here
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

  def step_forward_until_block_istrue
    until yield
      step_forward
      puts "One small step..."
    end

    puts "It's true!"
  end

  def reset
    self.step_forward_until {max_sensor?}
    @position = 0
  end

  def max_sensor?
    if RPi::GPIO.high? PIN_NUM
      return true
    else
      return false
    end
  end
end
