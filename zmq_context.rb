require 'singleton'
require 'ffi-rzmq'

require_relative 'zmq_socket.rb'

class ZMQContext
  include Singleton

  def initialize
    @context = ZMQ::Context.new

    ObjectSpace.define_finalizer(self, proc {
      @context.terminate
    })
  end

  def open_socket socket_type, ip, port, topic=""
    ZMQSocket.new socket_type, @context, ip, port, topic
  end
end
