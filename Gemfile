source "https://rubygems.org"

gem "rake"
gem "rails", "7.0.4"
gem "puma" # web server
# gem 'mimemagic', github: 'mimemagicrb/mimemagic', ref: '3543363026121ee28d98dfce4cb6366980c055ee' # Lastest version of mimemagic has copyright issues and breaks
gem "sprockets" # Latest version of sprockets 2.*. 3.* causes a failure at startup
gem "sprockets-rails"
# gem 'sprockets', '~> 3.5', '>= 3.5.2'
gem "tzinfo-data" # new requirement
gem "mysql2"
gem "haml-rails"
gem "sass-rails"
gem "uglifier", ">= 1.3.0"
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

gem "mail", "2.7.1" # latest version of mail does not work with rails 7.0.4 at the moment

gem 'bigdecimal', '>= 2.5.5' # To avoid BigDecimal.new error
gem 'terrapin'
gem 'flag_shih_tzu' # Used to implement bitfields in ActiveRecord models

gem "caxlsx"

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

group :test do
  gem "rspec-rails"
  gem "rails-controller-testing"
  gem "capybara"
  gem 'capybara-lockstep' # Used to make capybara tests more robust.
  gem "selenium-webdriver"
#   gem "chromedriver-helper" # (deprecated in favour of webdrivers)
  gem "webdrivers"
#   gem "factory_girl_rails", require: false # name changed to factory_bot_rails
  gem "factory_bot_rails"
  gem "launchy"
  gem "faker"
  gem "database_cleaner"
  #gem "byebug"
end
