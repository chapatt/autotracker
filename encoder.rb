require 'singleton'
require_relative 'gpio.rb'

class Encoder
  include Singleton

  PIN_ENC = 21
  CYCLES_PER_REV = 360

  attr_accessor :direction # Until initialized @position will not change
  attr_reader :position

  def initialize
    @callbacks = Hash.new
    @position = 0

    GPIO::setup PIN_ENC, with_direction: GPIO::DIRECTION_INPUT

    self.watch

    ObjectSpace.define_finalizer self, proc {
        if @enc_poll_thread
          @enc_poll_thread.exit
        end
        GPIO::cleanup PIN_ENC
    }
  end

  # Block should return false to delete callback
  def call_at pulse, &block
    if @callbacks[pulse].nil?
      @callbacks[pulse] = Array.new
    end
    @callbacks[pulse] << block
  end

  def reset_position
    @position = 0
  end

  def stop_watching
    if @enc_poll_thread
      @enc_poll_thread.exit
    end
    @enc_poll_thread = nil
  end

  def watch
    if @enc_poll_thread
      raise
    end

    @enc_poll_thread = Thread.new do
      GPIO::watch 21, on: GPIO::EDGE_FALLING do
        if @direction == :clockwise
          @position += 1
        elsif @direction == :counterclockwise
          @position -= 1
        end

        if @callbacks[@position]
          @callbacks[@position].each do |block|
            if !block.call
              @callbacks[@position].delete block
            end
          end
        end

        true
      end
    end
  end
end
