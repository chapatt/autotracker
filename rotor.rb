require 'rpi_gpio'
require 'singleton'

class Rotor
  include Singleton

  PIN_A4988_SLEEP =	2
  PIN_A4988_ENABLE =	3
  PIN_A4988_STEP =	4
  PIN_A4988_MS1 =	14
  PIN_A4988_MS2 =	15
  PIN_A4988_MS3 =	17
  PIN_A4988_DIR =	18
  PIN_A4988_RESET =	27

  MOTOR_STEPS = 400

  def initialize
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

    self.reset
  end

  def set_resolution(resolution)
    case resolution
    when :full, 1
      RPi::GPIO.set_low PIN_A4988_MS1
      RPi::GPIO.set_low PIN_A4988_MS2
      RPi::GPIO.set_low PIN_A4988_MS3
      return true
    when :half, 2
      RPi::GPIO.set_high PIN_A4988_MS1
      RPi::GPIO.set_low PIN_A4988_MS2
      RPi::GPIO.set_low PIN_A4988_MS3
      return true
    when :quarter, 4
      RPi::GPIO.set_low PIN_A4988_MS1
      RPi::GPIO.set_high PIN_A4988_MS2
      RPi::GPIO.set_low PIN_A4988_MS3
      return true
    when :eighth, 8
      RPi::GPIO.set_high PIN_A4988_MS1
      RPi::GPIO.set_high PIN_A4988_MS2
      RPi::GPIO.set_low PIN_A4988_MS3
      return true
    when :sixteenth, 16
      RPi::GPIO.set_high PIN_A4988_MS1
      RPi::GPIO.set_high PIN_A4988_MS2
      RPi::GPIO.set_high PIN_A4988_MS3
      return true
    else
      return false
    end
  end

  def to_bearing(bearing)
  end

  def to_relative_bearing(bearing)
    if !bearing.between?(0, 360)
      return false
    end
    to_position(MOTOR_STEPS * bearing / 360)
  end

  def to_position(position)
    step((position % MOTOR_STEPS) - @position)
  end

  def step(steps)
    # actually step here
    puts "Taking #{steps} steps!"
    @position += steps
  end

  def reset
    @position = 0
  end
end
