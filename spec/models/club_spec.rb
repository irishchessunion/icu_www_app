require 'rails_helper'

describe Club do
  let(:bangor) { create(:club) }

  context "secretary" do
    it "can be blank" do
      bangor.secretary_id = nil
      expect{ bangor.save! }.to_not raise_error
    end

    it "can be an existing player" do
      bangor.secretary_id = create(:player).id
      expect{ bangor.save! }.to_not raise_error
    end

    it "must reference an existing player" do
      bangor.secretary_id = 999999
      expect{ bangor.save! }.to raise_error(/does not exist/i)
    end
  end

  context "email" do
    # The clubs.email column used to be limited to 50 characters (issue #251)
    it "can be longer than 50 characters" do
      email = "#{'a' * 60}@#{'b' * 60}.ie"
      bangor.update!(email: email)
      expect(bangor.reload.email).to eq email
    end

    it "can't be longer than 254 characters" do
      bangor.email = "#{'a' * 64}@#{'b' * 190}.ie"
      expect(bangor).to_not be_valid
      expect(bangor.errors[:email]).to eq ["is too long (maximum is 254 characters)"]
    end
  end

  context "latitude and longitude" do
    it "can be blank" do
      bangor.lat = nil
      bangor.long = nil
      expect{ bangor.save! }.to_not raise_error
    end

    it "latitude has upper limit" do
      bangor.lat = 60
      expect{ bangor.save! }.to raise_error(/must be between/i)
    end

    it "latitude has lower limit" do
      bangor.lat = 40
      expect{ bangor.save! }.to raise_error(/must be between/i)
    end

    it "longitude has upper limit" do
      bangor.long = 10
      expect{ bangor.save! }.to raise_error(/must be between/i)
    end

    it "longitude has lower limit" do
      bangor.long = -20
      expect{ bangor.save! }.to raise_error(/must be between/i)
    end

    it "can be saved to 6 decimal places" do
      lat, long = 54.676051, -5.620965
      bangor.lat = lat
      bangor.long = long
      bangor.save!
      bangor.reload
      expect(bangor.lat).to be_within(0.000001).of(lat)
      expect(bangor.long).to be_within(0.000001).of(long)
    end

    it "can be given as strings" do
      lat, long = "54.676051", "-5.620965"
      bangor.lat = lat
      bangor.long = long
      bangor.save!
      bangor.reload
      expect(bangor.lat).to be_within(0.000001).of(lat.to_f)
      expect(bangor.long).to be_within(0.000001).of(long.to_f)
    end
  end

  context "county" do
    let(:bangor) { create(:club) }

    it "must not be blank or invalid" do
      [nil, "", "somerset", "Down"].each do |county|
        bangor.county = county
        expect{ bangor.save! }.to raise_error(/invalid county/i)
      end
    end
  end

  context "web" do
    let(:bangor) { create(:club) }

    it "can be blank" do
      bangor.web = nil
      expect{ bangor.save! }.to_not raise_error
    end

    it "should be a full URL" do
      bangor.web = "mailto:joe@example.club.com"
      expect{ bangor.save! }.to raise_error(/invalid/)
      bangor.web = "http://example.club.com"
      expect{ bangor.save! }.to_not raise_error
    end

    it "partial URLs can be repaired" do
      bangor.web = "example.club.com/home"
      expect{ bangor.save! }.to_not raise_error
      bangor.reload
      expect(bangor.web).to eq "http://example.club.com/home"
    end
  end

  context "location" do
    it "includes the address, distinct city, county and Eircode" do
      club = build(:club, address: "McKee Clock, Marina", city: "Bangor", county: "down", district: "Marina", eircode: "BT20 5ED")

      expect(club.location_parts).to eq ["McKee Clock", "Marina", "Bangor", "Co. Down", "BT20 5ED"]
      expect(club.location).to eq "McKee Clock, Marina, Bangor, Co. Down, BT20 5ED"
    end

    it "omits the city when it is the same as the county" do
      club = build(:club, address: "Trinity Sports & Leisure Club", city: "Dublin", county: "dublin", eircode: "D13 X651")

      expect(club.location_parts).to eq ["Trinity Sports & Leisure Club", "Co. Dublin", "D13 X651"]
      expect(club.location).to eq "Trinity Sports & Leisure Club, Co. Dublin, D13 X651"
    end
  end

  context "blank attributes" do
    it "are normalised" do
      club = create(:club, web: "", meet: "", address: "\s", district: " ", lat: "", long: "", contact: "", email: "", phone: "", active: false)
      expect(club.meet).to be_nil
      expect(club.district).to be_nil
      expect(club.address).to be_nil
      expect(club.contact).to be_nil
      expect(club.phone).to be_nil
      expect(club.email).to be_nil
      expect(club.web).to be_nil
      expect(club.lat).to be_nil
      expect(club.long).to be_nil
    end
  end

  context "meeting day search" do
    it "finds clubs by meeting day without duplicates" do
      tuesday = create(:club, name: "Tuesday Club")
      other = create(:club, name: "Wednesday Club")
      tuesday.club_meetings.create!(day_of_week: "tuesday", start_time: "19:00")
      tuesday.club_meetings.create!(day_of_week: "tuesday", start_time: "20:00")
      other.club_meetings.create!(day_of_week: "wednesday", start_time: "19:00")

      results = Club.search(day_of_week: "tuesday")
      expect(results.count).to eq(1)
      expect(results.to_a).to eq([tuesday])
    end
  end

  context "directory filters" do
    it "finds names and locations, treating search wildcards literally" do
      club = create(:club, address: "Community Hall", city: "Bangor", county: "down")
      %w[Chess Community Bangor down].each do |term|
        expect(Club.search(search: term)).to eq([club])
      end
      expect(Club.search(search: "%")).to be_empty
    end

    it "uses the legacy adults-only fallback only without structured meetings and with meeting text" do
      adult = create(:club, name: "Adult meetings")
      adult.club_meetings.create!(day_of_week: "monday", start_time: "19:00", welcomes_juniors: false)
      legacy = create(:club, name: "Legacy adults")
      create(:club, name: "No meetings", meet: nil)
      create(:club, name: "Junior section", has_junior_section: true)
      create(:club, name: "Junior club", junior_only: true)
      open = create(:club, name: "Open meetings")
      open.club_meetings.create!(day_of_week: "monday", start_time: "19:00")

      expect(Club.search(audience: "adults_only")).to contain_exactly(adult, legacy)
      expect(Club.search(audience: "adults_only", day_of_week: "monday")).to eq([adult])
    end

    it "combines day and audience on the same meeting and includes every audience by default" do
      club = create(:club)
      club.club_meetings.create!(day_of_week: "monday", start_time: "19:00", audience: "women_only")
      club.club_meetings.create!(day_of_week: "tuesday", start_time: "19:00", audience: "juniors_only")

      expect(Club.search(audience: "all")).to eq([club])
      expect(Club.search(audience: "women_only", day_of_week: "monday")).to eq([club])
      expect(Club.search(audience: "women_only", day_of_week: "tuesday")).to be_empty
      expect(Club.search(audience: "juniors_only")).to eq([club])
    end
  end

  context "notes editing" do
    it "renders legacy plain-text notes without raw HTML" do
      club = create(:club, notes: "Meets upstairs <script>alert(1)</script>")
      expect(club.html).to include("Meets upstairs")
      expect(club.html).to_not include("<script>")
    end

    it "sanitizes notes saved from the editor and clears an empty editor" do
      expect(create(:club, markdown: false, notes: "<p><em>Hi</em></p><img src=x onerror=alert(1)>").notes).to eq "<p><em>Hi</em></p>"
      expect(create(:club, name: "Empty Notes CC", markdown: false, notes: "<p><br></p>").notes).to be_nil
    end

    it "rejects images" do
      image = create(:image)
      club = build(:club, markdown: false, notes: "<p>[IMG:#{image.id}]</p>")
      expect(club).to_not be_valid
      expect(club.errors[:notes]).to eq ["can't include images"]
    end
  end
end
