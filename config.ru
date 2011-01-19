require 'rubygems'
require 'bundler'
Bundler.setup

$LOAD_PATH.unshift File.join File.dirname(__FILE__), 'lib'
require 'transform'

set :env, :production
disable :run, :reload

run Sinatra::Application