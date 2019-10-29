require 'yaml'

require_relative './lib/espect'

threads 5, 5
if Espect.config['ssl_port']
  ssl_bind Espect.config['bind_host'], Espect.config['ssl_port'] || 8899, key: Espect.config['ssl_key'], cert: Espect.config['ssl_cert'], verify_mode: 'none'
end
bind "tcp://#{Espect.config['bind_host'] || '0.0.0.0'}:#{Espect.config['port'] || 8898}"

prune_bundler
quiet false

if ENV['APP_ROOT']
  directory ENV['APP_ROOT']
end
