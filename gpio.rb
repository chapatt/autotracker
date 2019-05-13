EPOLL_LIB = 'sleepy_penguin'
#EPOLL_LIB = 'epoll'
require EPOLL_LIB
  
module GPIO
  DIRECTION_INPUT  = 'in'
  DIRECTION_OUTPUT = 'out'
  
  EDGE_NONE    = 'none'
  EDGE_RISING  = 'rising'
  EDGE_FALLING = 'falling'
  EDGE_BOTH    = 'both'
  
  STATE_LOW  = '0'
  STATE_HIGH = '1'

  # GPIO::TYPE_GPIO
  # :frequency in Hz, :duty_cycle in fraction of whole
  #
  # GPIO::TYPE_PWM
  # :direction either DIRECTION_INPUT or DIRECTION_OUTPUT
  # :active_low either true or false
  def self.setup pin, type, params={}
    if type == self.class::TYPE_PWM
      File.binwrite '/sys/class/pwm/pwmchip0/export', pin.to_s
      # Retry a few time until files appear
      retries = 0
      begin
        self.set_frequency pin params[:frequency]
        self.set_duty_cycle pin params[:duty_cycle]
      rescue
        raise if retries > 3
        sleep 0.1
        retries += 1
        retry
      end
    elsif type == self.class::TYPE_GPIO
      File.binwrite '/sys/class/gpio/export', pin.to_s
      # retry a few time until files appear
      retries = 0
      begin
        File.binwrite "/sys/class/gpio/gpio#{pin}/direction", params[:direction]
        if params[:active_low]
          File.binwrite "/sys/class/gpio/gpio#{pin}/active_low", '1'
        end
      rescue
        raise if retries > 3
        sleep 0.1
        retries += 1
        retry
      end
    end
  end
  
  def self.watch pin, on:
    # on should be 'none', 'rising', 'falling', or 'both'
    File.binwrite "/sys/class/gpio/gpio#{pin}/edge", on
  
    fd = File.open "/sys/class/gpio/gpio#{pin}/value", 'r'
    fd.read
  
    case EPOLL_LIB
    when 'epoll'
      epoll = Epoll.create
      epoll.add fd, Epoll::PRI
    when 'sleepy_penguin'
      epoll = SleepyPenguin::Epoll.new
      epoll.add fd, SleepyPenguin::Epoll::PRI
    end
  
    loop do
      fd.seek 0, IO::SEEK_SET
      epoll.wait(max_events=1) { }
  
      unless (yield fd.read.chomp)
        return
      end
    end
  end
  
  def self.set_state pin, state
    File.binwrite "/sys/class/gpio/gpio#{pin}/value", state.to_s
  end
  
  def self.cleanup pin
    if File.exist?("/sys/class/pwm/pwm#{pin}")
      File.binwrite '/sys/class/pwm/pwmchip0/unexport', pin.to_s
    elsif File.exist?("/sys/class/gpio/gpio#{pin}")
      File.binwrite '/sys/class/gpio/unexport', pin.to_s
    end
  end

  def self.set_pwm_frequency pin frequency
    period = 1000000000 / frequency
    File.binwrite "/sys/class/pwm/pwm#{pin}/period", period
  end

  def self.set_pwm_duty_cycle pin duty_cycle
    duty_length = period * duty_cycle
    File.binwrite "/sys/class/pwm/pwm#{pin}/duty_cycle", duty_cycle
  end

  def self.start_pwm pin
    File.binwrite "/sys/class/pwm/pwm#{pin}/enable", '1'
  end

  def self.stop_pwm pin
    File.binwrite "/sys/class/pwm/pwm#{pin}/enable", '0'
  end
end
