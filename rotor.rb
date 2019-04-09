require 'singleton'

class Rotor
  include Singleton

  attr_accessor :position

  def to_position position
    @position = position
  end
end
