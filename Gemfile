source "https://rubygems.org"

def next?
  File.basename(__FILE__) == "Gemfile.next"
end

gem "rake"

if next?
  gem "rails", "~> 7.2.0"
else
  gem "rails", "~> 7.1.0"
end

gem "next_rails"

# Ruby 3.2 includes `base64` as a default gem (0.1.1). Under Passenger it may be
# activated before Bundler loads, causing "already activated base64 0.1.1" errors
# if the lockfile wants a newer base64.
gem "base64", "0.1.1"

gem "puma", ">= 6.4.3" # web server
# gem 'mimemagic', github: 'mimemagicrb/mimemagic', ref: '3543363026121ee28d98dfce4cb6366980c055ee' # Lastest version of mimemagic has copyright issues and breaks
gem "sprockets" # Latest version of sprockets 2.*. 3.* causes a failure at startup
gem "sprockets-rails"
# gem 'sprockets', '~> 3.5', '>= 3.5.2'
gem "tzinfo-data" # new requirement
gem "mysql2"
gem "haml-rails"
gem "sass-rails"
#gem "uglifier", ">= 1.3.0"
gem "terser", "~> 1.2.6"
gem "mini_racer", platforms: :ruby
gem "jquery-rails"
gem "cancancan" # cancan is no longer maintained, newer version is cancancan
gem "redis"
# gem "therubyracer", platforms: :ruby # (no longer needed)
gem "icu_name", "1.3.0"
gem "icu_utils", "1.3.3"
gem "redcarpet", "3.6.1"
gem "stripe"
gem "mailgun-ruby", require: "mailgun"
# gem "paperclip"
gem "kt-paperclip"
# gem "colorize", "0.7.4" # To avoid capistrano error using ruby 2.4.0 -- https://github.com/Mixd/wp-deploy/issues/130
gem "colored"
gem "whenever", :require => false
# gem "quiet_assets" # (deprecated in favour of sprockets-rails)

gem "mail"

gem 'bigdecimal', '>= 2.5.5' # To avoid BigDecimal.new error
gem 'terrapin'
gem 'flag_shih_tzu' # Used to implement bitfields in ActiveRecord models

gem "caxlsx"
gem "rubyzip", "~> 2.3" # Pin to avoid RubyZip 3.0 breaking API changes

group :development do
  gem "capistrano" # For same reason as colorize comment above
  gem "capistrano-rvm"
  gem "capistrano-rails"
  gem 'capistrano-maintenance', '~> 1.2', require: false
  gem "wirble"
  # The following 2 gems are needed to support ed25519 encrypted keys for capistrano installs.
  gem "bcrypt_pbkdf"
  gem "ed25519"
end

group :development, :test do
  gem "byebug"
end

group :test do
  gem "rspec-rails"
  gem "rails-controller-testing"
  gem "capybara"
  gem 'capybara-lockstep' # Used to make capybara tests more robust.
  gem "selenium-webdriver", ">= 4.11" # 4.11+ includes Selenium Manager (replaces webdrivers)
  gem "factory_bot_rails"
  gem "launchy"
  gem "faker"
  gem "database_cleaner", ">= 2.1"
end

# Avoiding CVE problems - these are found with `bundle audit`
gem "nokogiri", ">= 1.18.9"
gem "rack", "~> 2.2.20"
gem "rexml", ">= 3.3.9"
gem "thor", ">= 1.4.0"