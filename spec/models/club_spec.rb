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

      results = Club.search({ day_of_week: "tuesday" }, "/clubs")
      expect(results.count).to eq(1)
      expect(results.matches.to_a).to eq([tuesday])
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
  end
end
