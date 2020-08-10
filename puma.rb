workers Integer(ENV['PUMA_WORKERS'] || 1)
threads Integer(ENV['MIN_THREADS']  || 1), Integer(ENV['MAX_THREADS'] || 8)

rackup      DefaultRackup
port        ENV['PORT']     || '9000'
environment ENV['RACK_ENV'] || 'production'

bind ENV['PUMA_SOCK'] || "unix:///var/run/dialer-api/puma.sock"

on_restart do
  REDIS.client.reconnect
end

on_worker_boot do

end

# preload_app!
activate_control_app
