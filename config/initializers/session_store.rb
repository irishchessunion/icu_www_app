# At the moment Apache redirects icu.ie to www.icu.ie. If it didn't, then adding:
#
#   domain: ".icu.ie"
#
# (in production only of course) would make sure sessions get shared between the two.
#
# Share login sessions between www and non-www in production, and keep them across
# browser restarts for 14 days between visits.
IcuWwwApp::Application.config.session_store :cookie_store,
  key: "_www_session",
  expire_after: 14.days,
  domain: Rails.env.production? ? ".icu.ie" : nil
