require 'singleton'
require_relative 'gpio.rb'

class HomeSensor
  include Singleton

  PIN_HOME = 12

  def initialize
    GPIO::setup PIN_HOME, GPIO::TYPE_GPIO, { direction => GPIO::DIRECTION_INPUT }

    self.watch

    ObjectSpace.define_finalizer self, proc { @home_poll_thread.exit }
  end

  # Block should return false to delete callback
  def call_on_edge &block
    if @callbacks.nil?
      @callbacks = Array.new
    end
    @callbacks << block
  end

  def stop_watching
    if @home_poll_thread
      @home_poll_thread.exit
    end
    @home_poll_thread = nil
  end

  def watch
    if @home_poll_thread
      raise
    end

    @home_poll_thread = Thread.new do
      GPIO::watch PIN_ENC, on: GPIO::EDGE_BOTH do
        if @callbacks
          @callbacks.each do |block|
            if !block.call
              @callbacks.delete block
            end
          end
        end
      end
    end
  end
end
