require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "active_support"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# General configuration.
module IcuWwwApp
  class Application < Rails::Application
    # Rails 7.2 removed Rails.application.secrets. This shim adds it back via config_for
    # so the rest of the codebase doesn't need to change during dual-boot.
    def secrets
      @_secrets ||= config_for(:secrets)
    end

    config.load_defaults NextRails.next? ? 8.0 : 7.2

    # Disable belongs_to required by default (introduced in 5.0 load_defaults).
    # The app's models rely on optional belongs_to associations.
    config.active_record.belongs_to_required_by_default = false

    # Express preference for double quoted attributes (single quoted is HAML's default).
    Haml::Template.options[:attr_wrapper] = '"'

    # Autoload lib/ directory.
    config.autoload_lib(ignore: %w[assets tasks])

    # The following is recomended since 4.1. See also http://stackoverflow.com/questions/20361428/rails-i18n-validation-deprecation-warning.
    I18n.config.available_locales = [:en, :ga]
    I18n.config.enforce_available_locales = true

    # Autoload nested locales for the simple backend.
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.yml")]

    # Enable locale fallbacks for I18n for all environments.
    config.i18n.fallbacks = true

    # Do not swallow errors in after_commit/after_rollback callbacks. (no longer a valid option)
    # config.active_record.raise_in_transactional_callbacks = true

    # legacy_connection_handling removed in Rails 7.1
  end
end
