# Load DSL and set up stages
require "capistrano/setup"

# Includes default deployment tasks
require "capistrano/deploy"

# Includes tasks from other gems included in your Gemfile
require "capistrano/bundler"
require "capistrano/rails/assets"
require "capistrano/rails/migrations"

require "capistrano/maintenance"
require "capistrano/rvm"
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
