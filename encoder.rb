require 'singleton'
require_relative 'gpio.rb'

class Encoder
  include Singleton

  PIN_ENC = 27
  PIN_DIR = 17
  CYCLES_PER_REV = 360

  DIR_CW =  1
  DIR_CCW = 0

  attr_accessor :position,
                :direction

  def initialize
    @callbacks = Hash.new
    @position = 0
    @callback_mutex = Mutex.new

    GPIO::setup PIN_ENC, GPIO::TYPE_GPIO, { :direction => GPIO::DIRECTION_INPUT }
    GPIO::setup PIN_DIR, GPIO::TYPE_GPIO, { :direction => GPIO::DIRECTION_INPUT }

    @direction = GPIO::read_state PIN_DIR

    self.watch

    ObjectSpace.define_finalizer self, proc {
        if @enc_poll_thread
          @enc_poll_thread.exit
        end
        GPIO::cleanup PIN_ENC
        GPIO::cleanup PIN_DIR
    }
  end

  # Block should return false to delete callback
  def call_at pulse, &block
    @callback_mutex.synchronize do
      if @callbacks[pulse].nil?
        @callbacks[pulse] = Array.new
      end
      @callbacks[pulse] << block
    end
  end

  def stop_watching
    if @dir_poll_thread
      @dir_poll_thread.exit
    end
    @dir_poll_thread = nil

    if @enc_poll_thread
      @enc_poll_thread.exit
    end
    @enc_poll_thread = nil
  end

  def watch
    if @dir_poll_thread
      raise
    end

    @dir_poll_thread = Thread.new do
      GPIO::watch PIN_DIR, on: GPIO::EDGE_BOTH do |state|
        @direction = state
        true
      end
    end

    if @enc_poll_thread
      raise
    end

    @enc_poll_thread = Thread.new do
      GPIO::watch PIN_ENC, on: GPIO::EDGE_FALLING do
        if @direction == DIR_CW
          @position += 1
        elsif @direction == DIR_CCW
          @position -= 1
        end

        @callback_mutex.synchronize do
          if @callbacks[@position]
            @callbacks[@position].each do |block|
              if !block.call
                @callbacks[@position].delete block
              end
            end
          end
        end

        true
      end
    end
  end
end
