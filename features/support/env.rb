require File.dirname(__FILE__) + "/../../transform"

# Force the application name because polyglot breaks the auto-detection logic.
Sinatra::Application.app_file = File.join(File.dirname(__FILE__), "/../../transform")
require 'rack/test'
# RSpec matchers
require 'spec/expectations'

Sinatra::Application.set :environment, :development

World do
  def app
      Transform
  end
  include Rack::Test::Methods
end
