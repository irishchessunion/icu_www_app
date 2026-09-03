# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'database_cleaner'
require 'factory_bot_rails'
require 'faker'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

Capybara.configure do |config|
  config.default_max_wait_time = 5 # be patient with Ajax wait times (includes waiting for Stripe)
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # Disable Rspecs transactional fixtures by default
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do |example|
    # Use truncation only for capybara/selenium tests
    if example.metadata[:js]
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
    end
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # Capture what the browser actually shows on a failed js: true example, so
  # an intermittent Capybara::ElementNotFound can be diagnosed from real
  # evidence (was it an error page? a login/auth redirect? the right page but
  # missing content?) instead of guesswork. Saved under tmp/capybara/.
  config.after(:each) do |example|
    next unless example.exception && example.metadata[:js]

    dir = Rails.root.join("tmp", "capybara")
    FileUtils.mkdir_p(dir)
    name = "#{Time.now.strftime('%Y%m%d%H%M%S')}_#{example.full_description.parameterize(separator: '_')[0, 80]}"
    begin
      page.save_screenshot(dir.join("#{name}.png"))
      File.write(dir.join("#{name}.html"), page.html)
      puts "Saved failure screenshot/HTML: #{dir.join(name)}.{png,html}"
    rescue => e
      warn "Could not save failure screenshot for #{example.full_description}: #{e.message}"
    end
  end

  config.infer_spec_type_from_file_location!
end

# Create and login a user with a given role or roles.
def login(user_or_roles=nil, options={})
  visit sign_out_path
  return if user_or_roles == "guest"
  visit sign_in_path
  user, roles = user_or_roles.instance_of?(User) ? [user_or_roles, nil] : [nil, user_or_roles]
  user ||= create(:user, roles: roles)
  fill_in I18n.t("email"), with: options[:email] || user.email
  fill_in I18n.t("user.password"), with: options[:password] || "password"
  click_button I18n.t("session.sign_in")

  # Signing in either redirects (session#create -> last_page_before_sign_in_or_home
  # -> GET, on success) or re-renders "new" in the same response (on failure,
  # e.g. expired subscription/bad password - some specs deliberately login with
  # bad credentials to check the resulting Login record). If the caller's next
  # step is another `visit`/`click` before whichever of those has finished, the
  # browser can resolve to a stale pre-visit target instead of the page the
  # caller asks for next. Wait for a flash message - present in both the
  # success and failure case - so we only return once that has settled.
  expect(page).to have_css("#flash_messages .text-center", wait: 5)
  user
end

# Logout the current user.
def logout
  visit sign_out_path
end

# Confirm a popup confirmation dialog.
def confirm_dialog(delay=0.2)
  sleep(delay)
  page.driver.browser.switch_to.alert.accept
  sleep(delay)
end

# General purpose wait for a while.
def wait_a_second(delay=0.3)
  sleep(delay)
end

# Opens the "select member" modal (used throughout the shop/cart flow - see
# app/views/items/_player_ids_button.html.haml), searches for the given
# player and picks them. Waits for the modal to actually finish opening
# (Bootstrap's fade transition) instead of a fixed sleep, which flakes under
# any variation in page load time.
def pick_cart_member(player)
  click_button I18n.t("item.member.select")
  expect(page).to have_css("#player_ids_modal.in", wait: 5)
  fill_in I18n.t("player.last_name"), with: player.last_name + "\n"
  fill_in I18n.t("player.first_name"), with: player.first_name + "\n"
  click_link player.id.to_s
end
