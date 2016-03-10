namespace :pgn do
  desc "Generate a refreshed PGN database"
  task :db, [:force] => :environment do |_, args|
    ICU::PGN.new.database(args[:force])
  end
end
