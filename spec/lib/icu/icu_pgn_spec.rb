require 'rails_helper'

describe ICU::PGN do
  let(:dir) { Pathname.new(Dir.mktmpdir) }

  before(:each) do
    stub_const("Game::PGN_FILE", dir + "icu.pgn")
    stub_const("Game::ZIP_FILE", dir + "icu.pgn.zip")
    stub_const("Game::LOG_FILE", dir + "last_pgn_db.norotate")
    create(:game)
  end

  after(:each) { FileUtils.rm_rf(dir) }

  it "builds the PGN file and its zip, then skips the next run if no game has changed" do
    expect { ICU::PGN.new.database(false) }.to output(/compressed PGN/).to_stdout
    expect(File.read(Game::PGN_FILE)).to include("[Event ")
    expect(File.size(Game::ZIP_FILE)).to be > 0
    expect(Game.get_last_pgn_db.first).to eq Game.maximum(:updated_at).to_fs(:db)

    expect { ICU::PGN.new.database(false) }.to output(/has not changed/).to_stdout
    expect { ICU::PGN.new.database(true) }.to output(/compressed PGN/).to_stdout
  end
end
