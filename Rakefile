# The following gems are required in order to deploy through capistrano
# gem install capistrano -v 2.11.2
# gem install railsless-deploy -v 2.1.2
require 'rake'
require 'rake/task'
require 'cucumber/rake/task'
require 'rspec/core'
require 'rspec/core/rake_task'

Cucumber::Rake::Task.new

desc "rspec"
task :rspec do
  RSpec::Core::RakeTask.new do |t|
    t.pattern = "./**/*_spec.rb"
    t.ruby_opts = "-w"
    #t.libs << 'lib'
    #t.libs << 'spec'
  end
end

# -*- mode:ruby; -*-

HOME    = File.expand_path(File.dirname(__FILE__))

# map local users to server users

if ENV["USER"] == "Carol"
  user = "cchou"
else
  user = ENV["USER"]
end

desc "Hit the restart button for apache/passenger, pow servers"
task :restart do
  sh "touch #{HOME}/tmp/restart.txt"
end

# Build local bundled Gems; 

desc "Gem bundles"
task :bundle do
  sh "rm -rf #{HOME}/bundle #{HOME}/.bundle #{HOME}/Gemfile.lock"
  sh "mkdir -p #{HOME}/bundle"
  sh "cd #{HOME}; bundle --gemfile Gemfile install --path bundle"
end


desc "deploy to darchive's production site (transform.fda.fcla.edu)"
task :darchive do
  sh "cap deploy -S target=darchive.fcla.edu:/opt/web-services/sites/transform -S who=#{user}:#{user}"
end

desc "deploy to development site (transform.retsina.fcla.edu)"
task :retsina do
  sh "cap deploy -S target=retsina.fcla.edu:/opt/web-services/sites/transform -S who=daitss:daitss"
end

desc "deploy to development site (transform.marsala.fcla.edu)"
task :marsala do
  sh "cap deploy -S target=marsala.fcla.edu:/opt/web-services/sites/transform -S who=#{user}:#{user}"
end

desc "deploy to ripple's test site (transform.ripple.fcla.edu)"
task :ripple do
  sh "cap deploy -S target=ripple.fcla.edu:/opt/web-services/sites/transform -S who=#{user}:#{user}"
end

desc "deploy to tarchive's coop (transform.tarchive.fcla.edu?)"
task :tarchive_coop do
  sh "cap deploy -S target=tarchive.fcla.edu:/opt/web-services/sites/coop/transform -S who=#{user}:#{user}"
end

defaults = [:restart]

task :default => defaults
