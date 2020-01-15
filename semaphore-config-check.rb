require 'yaml'

class SemaphoreAgent
  MACHINE_TYPE_WHITE_LIST = %w(e1-standard-2 e1-standard-4).freeze
  MACHINE_OS_WHITE_LIST   = %w(ubuntu1804).freeze

  def initialize(config_hash)
    @config = config_hash['agent']
  end

  def valid?
    MACHINE_TYPE_WHITE_LIST.include?(@config['machine']['type']) && MACHINE_OS_WHITE_LIST.include?(@config['machine']['os_image'])
  end

  def errors
    errors_hash = {}
    unless valid?
      unless MACHINE_TYPE_WHITE_LIST.include?(@config['machine']['type'])
        errors_hash[:machine_type] = "Should be among #{MACHINE_TYPE_WHITE_LIST.join(', ')}"
      end
      unless MACHINE_OS_WHITE_LIST.include?(@config['machine']['os_image'])
        errors_hash[:machine_os_image] = "Should be among #{MACHINE_OS_WHITE_LIST.join(', ')}"
      end
    end
    errors_hash
  end
end

class SemaphoreCancel
  attr_accessor :config
  def initialize(config_hash)
    @config = config_hash.key?('auto_cancel') ? config_hash['auto_cancel'] : nil
  end

  def valid?
    return false if @config.nil?

    @config.key?('running') && @config['running'].key?('when')
  end

  def errors
    return {} if valid?

    { auto_cancel: 'should be present and set to anyting but the master branch' }
  end
end

class SemaphoreConfig
  attr_accessor :cancel_config

  def initialize(config_path = '.semaphore/semaphore.yml')
    @config = YAML.safe_load(IO.read(config_path))
    @agent = SemaphoreAgent.new(@config)
    @cancel_config = SemaphoreCancel.new(@config)
  end

  def valid?
    @agent.valid? && @cancel_config.valid?
  end

  def errors
    @agent.errors.merge(@cancel_config.errors)
  end
end

puts 'Semaphore config checks'

config = SemaphoreConfig.new

if config.valid?
  puts 'ok'
  exit 0
end

config.errors.map { |k, v| puts "#{k} : #{v}" }
exit 1
