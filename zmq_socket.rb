require 'ffi-rzmq'
require 'socket'

class ZMQSocket
  ZMQ_PORT_RANGE = (49152..65535)

  def initialize socket_type, context, ip, port, topic=""
    @sockets = []

    case socket_type
    when :PUB
      @sockets << (@socket = context.socket(ZMQ::PUB))
      rc = @socket.bind("tcp://#{ip}:#{port}")
      ZMQ::Util.error_check(@socket, rc)
    when :SUB
      @sockets << (@socket = context.socket(ZMQ::SUB))
      rc = @socket.setsockopt(ZMQ::SUBSCRIBE, topic)
      ZMQ::Util.error_check(@socket, rc)
      rc = @socket.connect("tcp://#{ip}:#{port}")
      ZMQ::Util.error_check(@socket, rc)
    when :proxied_REP
      @sockets << (@router = context.socket(ZMQ::ROUTER))
      rc = @router.bind("tcp://#{ip}:#{port}")
      ZMQ::Util.error_check(@router, rc)
  
      @sockets << (@dealer = context.socket(ZMQ::DEALER))
      dealer_inproc = 0
      loop do
        rc = @dealer.bind("inproc://#{dealer_inproc}")
        begin
          ZMQ::Util.error_check(@dealer, rc)
          break
        rescue ZMQ::ZeroMQError => e
          puts e.message
          dealer_inproc += 1
        end
      end
  
      @sockets << (@socket = context.socket(ZMQ::REP))
      rc = @socket.connect("inproc://#{dealer_inproc}")
      ZMQ::Util.error_check(@socket, rc)
  
      @proxy_thread = Thread.new do
          @proxy = ZMQ::Proxy.new(@router, @dealer)
      end
    when :REQ
      @sockets << (@socket = context.socket(ZMQ::REQ))
      rc = @socket.connect("tcp://#{ip}:#{port}")
      ZMQ::Util.error_check(@socket, rc)
    end

    ObjectSpace.define_finalizer(self, proc {
      self.close
    })
  end

  def close
    @sockets.each do |socket|
      socket.close if socket
      @sockets.delete socket
    end
  end

  def send_with_topic topic, message
    rc = @socket.send_string(topic, ZMQ::SNDMORE)
    ZMQ::Util.error_check(@socket, rc)
    rc = @socket.send_string(message)
    ZMQ::Util.error_check(@socket, rc)
  end

  def send message
    rc = @socket.send_string(message)
    ZMQ::Util.error_check(@socket, rc)
  end

  def receive_with_topic
    topic = ""
    rc = @socket.recv_string(topic)
    ZMQ::Util.error_check(@socket, rc)
    message = ""
    rc = @socket.recv_string(message)
    ZMQ::Util.error_check(@socket, rc)

    return message
  end

  def receive
    message = ""
    rc = @socket.recv_string(message)
    ZMQ::Util.error_check(@socket, rc)

    return message
  end

  def self.can_open_port? ip, port
    TCPServer.open(ip, port) { true } rescue false
  end

  def self.find_open_port ip
    while !(can_open_port? ip, (port = rand(ZMQ_PORT_RANGE))) do end

    return port
  end
end
