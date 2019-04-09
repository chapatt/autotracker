#require 'epoll'
require 'sleepy_penguin'
  
module GPIO
  DIRECTION_INPUT =  "in"
  DIRECTION_OUTPUT = "out"
  
  EDGE_NONE =    "none"
  EDGE_RISING =  "rising"
  EDGE_FALLING = "falling"
  EDGE_BOTH =    "both"
  
  STATE_LOW =  "0"
  STATE_HIGH = "1"
  
  def self.setup pin, with_direction:, active_low: false
    File.binwrite "/sys/class/gpio/export", pin.to_s
    # It takes time for the pin support files to appear, so retry a few times
    retries = 0
    begin
      File.binwrite "/sys/class/gpio/gpio#{pin}/direction", with_direction
      if active_low
        File.binwrite "/sys/class/gpio/gpio#{pin}/active_low", "1"
      end
    rescue
      raise if retries > 3
      sleep 0.1
      retries += 1
      retry
    end
  end
  
  def self.watch pin, on:
    # on should be "none", "rising", "falling", or "both"
    File.binwrite "/sys/class/gpio/gpio#{pin}/edge", on
  
    fd = File.open "/sys/class/gpio/gpio#{pin}/value", 'r'
    fd.read
  
=begin
    epoll = Epoll.create
    epoll.add fd, Epoll::PRI
=end
    epoll = SleepyPenguin::Epoll.new
    epoll.add fd, SleepyPenguin::Epoll::PRI
  
    loop do
      fd.seek 0, IO::SEEK_SET
      epoll.wait(max_events=1) { }
  
      unless (yield fd.read.chomp)
        return
      end
    end
  end
  
  def self.set pin, to:
    File.binwrite "/sys/class/gpio/gpio#{pin}/value", to.to_s
  end
  
  def self.cleanup pin
    File.binwrite "/sys/class/gpio/unexport", pin.to_s
  end
end
