# Rails 7.2 removed Rails.application.secrets. This shim adds it back via config_for
# so the rest of the codebase doesn't need to change during dual-boot.
if NextRails.next?
  IcuWwwApp::Application.class_eval do
    def secrets
      @_secrets ||= config_for(:secrets)
    end
  end
end
