ENV['RACK_ENV'] = 'production'
ENV['PORT'] = '9000'

require File.expand_path('../application', __FILE__)
