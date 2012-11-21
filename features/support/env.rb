require "rubygems"
require "bundler"
Bundler.setup

require File.dirname(__FILE__) + "/../../app"

# Force the application name because polyglot breaks the auto-detection logic.
# Sinatra::Application.app_file = File.join(File.dirname(__FILE__), "/../../transform")

require 'rack/test'
require 'rspec/expectations'
require 'ruby-debug'

Sinatra::Application.set :environment, :test

World do
  def app
    Sinatra::Application
  end

  include Rack::Test::Methods
end

