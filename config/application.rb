$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'api'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'boot'

Bundler.require :default, ENV['RACK_ENV']

require 'grape'
require 'sequel'
require 'sucker_punch'
require 'json'
require 'yaml'

DB = Sequel.connect(ENV['DATABASE_URL'])
DB.extension(:connection_validator)

Sequel.default_timezone = :utc
Sequel.datetime_class = Time

ENV['NOTIF_REDIS_URL'] ||= 'redis://127.0.0.1:6379/2'
REDIS_NOTIF = Redis.new(:url => ENV['NOTIF_REDIS_URL'])

ENV['REDIS_URL'] ||= 'redis://127.0.0.1'
REDIS = Redis.new(:url => ENV['REDIS_URL'])

root_path = File.expand_path File.dirname('../')

REPORT_DIR = "#{root_path}/public"

SuckerPunch.logger = Grape::API.logger
SuckerPunch.shutdown_timeout = 5

Dir["#{root_path}/lib/*.rb"].each { |lib| require lib }
Dir["#{root_path}/api/base/*.rb"].each { |api| require api }
Dir["#{root_path}/api/*.rb"].each { |api| require api }
Dir["#{root_path}/models/*.rb"].each  { |model_rb| require model_rb }
Dir["#{root_path}/presentations/*.rb"].each  { |present_rb| require present_rb }
Dir["#{root_path}/workers/*.rb"].each  { |worker_rb| require worker_rb }

