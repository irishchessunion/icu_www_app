IcuWwwApp::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = false

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send.
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { :host => "127.0.0.1:3000" }
  config.action_mailer.smtp_settings =
  {
    authentication: :plain,
    address: "smtp.mailgun.org",
    port: 587,
    domain: "icu.ie",
    user_name: "postmaster@icu.ie",
    password: Rails.application.secrets.mailgun[:password],
    enable_starttls_auto: false,
  }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :terser
  config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Generate digests for assets URLs.
  config.assets.digest = true

  config.log_level = :info

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages. (Causes more trouble than it's worth - MO).
  # config.assets.raise_runtime_errors = true

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Configure sensitive parameters which will be filtered from the log file.
  config.filter_parameters += [:password]

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
end
