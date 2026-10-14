# The tasks which converted the old ICU database (icuadmi_main) and the ratings database into this one
# ran once, on 2014-07-23, and have since been removed (see git history before October 2026 for them).
# The check is still useful: it looks for broken links between players, users, clubs and games.
#   $ bin/rake sync:check
namespace :sync do
  desc "Check links between players, users, clubs and games"
  task :check => :environment do |task|
    ICU::Legacy::Check.new.check
  end
end
