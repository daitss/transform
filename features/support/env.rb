require "rubygems"
require "bundler/setup"
require 'rspec'
require 'rspec/expectations'
require 'rack/test'
Bundler.setup

require File.dirname(__FILE__) + "/../../app"

# Force the application name because polyglot breaks the auto-detection logic.
# Sinatra::Application.app_file = File.join(File.dirname(__FILE__), "/../../transform")

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end

Sinatra::Application.set :environment, :test

World do
  def app
    Sinatra::Application
  end

  include Rack::Test::Methods
end

