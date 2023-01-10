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
gem "redcarpet"
gem "stripe"
gem "mailgun-ruby", require: "mailgun"
# gem "paperclip"
gem "kt-paperclip"
# gem "colorize", "0.7.4" # To avoid capistrano error using ruby 2.4.0 -- https://github.com/Mixd/wp-deploy/issues/130
gem "colored"
gem "whenever", :require => false
# gem "quiet_assets" # (deprecated in favour of sprockets-rails)

gem 'bigdecimal', '>= 2.5.5' # To avoid BigDecimal.new error
gem 'terrapin'

group :development do
  gem "capistrano" # For same reason as colorize comment above
  gem "capistrano-rails"
  gem "wirble"
end

group :development, :test do
  gem "rspec-rails"
  gem "rails-controller-testing"
  gem "capybara"
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
