require 'singleton'
require 'json'

require_relative 'positioner_frontend_streaming_interface.rb'
require_relative 'positioner_frontend_rest_interface.rb'

class WebPositionerFrontend
  include Singleton

  def initialize
    @read_thread
    @queue_browse_mutex = Mutex.new

    @streaming_if_msg_callbacks = []

    @queues = {}
    PositionerFrontendRESTInterface::browse do |mq_change|
      case mq_change[:type]
      when :add
        @queue_browse_mutex.synchronize do
          @queues[mq_change[:id]] = mq_change[:mq]
        end
      when :remove
        @queues.delete mq_change[:id]
      end
    end
  end

  attr_accessor :streaming_if_msg_callbacks

  def on_streaming_if_msg &block
    @streaming_if_msg_callbacks.push block
  end

  def emit_streaming_if_msg msg
    @streaming_if_msg_callbacks.each do |callback|
      callback.call msg
    end
  end

  attr_reader :positioner
  def positioner=(positioner)
    if @positioner
      @positioner.closeSocket
    end
    @positioner = positioner
    if @positioner
      puts 'Trying to open REST socket'
      @positioner.openSubscriberSocket
      puts 'Requesting streaming port'
      @positioner.send({ 'resource' => 'frontend-streaming-port', 'method' => 'GET' }.to_json)
      positioner_frontend_streaming_port = JSON.parse(@positioner.receive)['data'].to_i
      puts "Received port #{positioner_frontend_streaming_port}"

      @positioner_streaming_if = PositionerFrontendStreamingInterface.new @positioner.name, @positioner.address, positioner_frontend_streaming_port
      @positioner_streaming_if.openSubscriberSocket

      @sub_thread = Thread.new do
        while msg = @positioner_streaming_if.receive_with_type do
          self.emit_streaming_if_msg msg
        end
      end
    end
  end

  def positioners_available
    @queues
  end

  def to_rel_bearing bearing
      @positioner.send({ 'resource' => 'rel-bearing', 'method' => 'PUT', 'data' => bearing }.to_json)
      @positioner.receive
  end
end
