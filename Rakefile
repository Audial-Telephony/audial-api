require 'rubygems'
require 'bundler'
require 'sequel'
require 'yaml'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'

# require 'rspec/core'
# require 'rspec/core/rake_task'

# RSpec::Core::RakeTask.new(:spec) do |spec|
#   # do not run integration tests, doesn't work on TravisCI
#   spec.pattern = FileList['spec/api/*_spec.rb']
# end

# task :default => :spec
# task :test => :spec

namespace :db do
  namespace :migrate do
    Sequel.extension :migration

    ENV['RACK_ENV'] ||= 'production'

    task :connect do
      puts ENV['DATABASE_URL']
      if ENV['DATABASE_URL']
        # DB = Sequel.sqlite(ENV['DATABASE_URL'])
        DB = Sequel.connect(ENV['DATABASE_URL'])
      else
        puts 'ABORTING: You must set the DATABASE_URL environment variable!'
        exit false
      end
    end

    desc 'Perform migration up to latest migration available.'
    task :up => [:connect] do
      puts "Database: #{DB}"
      Sequel::Migrator.run(DB, "db/migrations")
      puts '*** db:migrate:up executed ***'
    end

    desc 'Perform migration down (erase all data).'
    task :down => [:connect] do
      Sequel::Migrator.run(DB, "db/migrations")
      puts '*** db:migrate:down executed ***'
    end

    end
end
