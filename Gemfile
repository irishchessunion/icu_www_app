source "https://rubygems.org"

gem "rake", "10.4.2"
gem "rails", "4.2.8"
gem "sprockets", "2.12.3" # Latest version of sprockets 2.*. 3.* causes a failure at startup
gem "mysql2"
gem "haml-rails"
gem "sass-rails", "~> 5.0"
gem "uglifier", ">= 1.3.0"
gem "jquery-rails"
gem "cancan", "~> 1.6"
gem "redis"
gem "therubyracer", platforms: :ruby
gem "icu_name"
gem "icu_utils", "1.3.1", git: 'https://github.com/ninkibah/icu_utils.git'
gem "redcarpet"
gem "stripe"
gem "mailgun-ruby", require: "mailgun"
gem "paperclip", "~> 4.1"
# gem "colorize", "0.7.4" # To avoid capistrano error using ruby 2.4.0 -- https://github.com/Mixd/wp-deploy/issues/130
gem "colored"
gem "whenever", :require => false
gem "quiet_assets"

group :development do
  gem "capistrano", "3.4.1" # For same reason as colorize comment above
  gem "capistrano-rails", "~> 1.1"
  gem "wirble"
end

group :development, :test do
  gem "rspec-rails", "~> 3.0"
  gem "capybara"
  gem "selenium-webdriver"
  gem "chromedriver-helper"
  gem "factory_girl_rails", "~> 4.0", require: false
  gem "launchy"
  gem "faker"
  gem "database_cleaner"
  #gem "byebug"
end
