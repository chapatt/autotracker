require 'singleton'

class Rotor
  include Singleton

  attr_accessor :rel_bearing

  def to_rel_bearing rel_bearing
    @rel_bearing = rel_bearing
  end
end
