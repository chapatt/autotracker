unless $simulate
require 'rpi_gpio'
end # unless $simulate
require 'singleton'

require_relative 'simulator.rb'

class Stepper
  include Singleton

  PIN_A4988_SLEEP =     2
  PIN_A4988_ENABLE =    3
  PIN_A4988_STEP =      4
  PIN_A4988_MS1 =       14
  PIN_A4988_MS2 =       15
  PIN_A4988_MS3 =       17
  PIN_A4988_DIR =       18
  PIN_A4988_RESET =     27

  def initialize
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
    end # unless $simulate
  end

  def set_resolution(resolution)
    case resolution
    when 1
      unless $simulate
      RPi::GPIO.set_low PIN_A4988_MS1
      RPi::GPIO.set_low PIN_A4988_MS2
      RPi::GPIO.set_low PIN_A4988_MS3
      end # unless $simulate
      Simulator.instance.pin_ms1 = :low
      Simulator.instance.pin_ms2 = :low
      Simulator.instance.pin_ms3 = :low
      return true
    when 2
      unless $simulate
      RPi::GPIO.set_high PIN_A4988_MS1
      RPi::GPIO.set_low PIN_A4988_MS2
      RPi::GPIO.set_low PIN_A4988_MS3
      end # unless $simulate
      Simulator.instance.pin_ms1 = :high
      Simulator.instance.pin_ms2 = :low
      Simulator.instance.pin_ms3 = :low
      return true
    when 4
      unless $simulate
      RPi::GPIO.set_low PIN_A4988_MS1
      RPi::GPIO.set_high PIN_A4988_MS2
      RPi::GPIO.set_low PIN_A4988_MS3
      end # unless $simulate
      Simulator.instance.pin_ms1 = :low
      Simulator.instance.pin_ms2 = :high
      Simulator.instance.pin_ms3 = :low
      return true
    when 8
      unless $simulate
      RPi::GPIO.set_high PIN_A4988_MS1
      RPi::GPIO.set_high PIN_A4988_MS2
      RPi::GPIO.set_low PIN_A4988_MS3
      end # unless $simulate
      Simulator.instance.pin_ms1 = :high
      Simulator.instance.pin_ms2 = :high
      Simulator.instance.pin_ms3 = :low
      return true
    when 16
      unless $simulate
      RPi::GPIO.set_high PIN_A4988_MS1
      RPi::GPIO.set_high PIN_A4988_MS2
      RPi::GPIO.set_high PIN_A4988_MS3
      end # unless $simulate
      Simulator.instance.pin_ms1 = :high
      Simulator.instance.pin_ms2 = :high
      Simulator.instance.pin_ms3 = :high
      return true
    else
      return false
    end
  end

  def set_dir(state)
    if state == :high
      unless $simulate
      RPi::GPIO.set_high PIN_A4988_DIR
      end # unless $simulate
      Simulator.instance.pin_dir = :high
    elsif state == :low
      unless $simulate
      RPi::GPIO.set_low PIN_A4988_DIR
      end # unless $simulate
      Simulator.instance.pin_dir = :low
    else
      return false
    end
  end

  def set_step(state)
    if state == :high
      unless $simulate
      RPi::GPIO.set_high PIN_A4988_STEP
      end # unless $simulate
      Simulator.instance.pin_step = :high
    elsif state == :low
      unless $simulate
      RPi::GPIO.set_low PIN_A4988_STEP
      end # unless $simulate
      Simulator.instance.pin_step = :low
    else
      return false
    end
  end
end
