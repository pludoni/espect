require 'yaml'

module Espect
  DEFAULTS = {
    'bind_host' => '0.0.0.0',
    'ssl_port' => nil,
    'ssl_key' => nil,
    'ssl_cert' => nil
  }.freeze
  def self.config
    @config ||= begin
      config_path = File.expand_path('../config.yml', __dir__)
      DEFAULTS.merge(YAML.load_file(config_path))
    end
  end
end
