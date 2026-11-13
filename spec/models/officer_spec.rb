require 'rails_helper'

describe Officer do
  let(:ratings) { create(:officer, name: "Rating Officer") }

  context "validation" do
    it "needs a name" do
      expect(build(:officer, name: " ")).to_not be_valid
    end

    it "needs a unique name" do
      expect(build(:officer, name: ratings.name)).to_not be_valid
    end

    it "tidies the name" do
      expect(create(:officer, name: "  Arbiters   Officer ").name).to eq "Arbiters Officer"
    end

    it "doesn't need a role" do
      create(:officer, role: nil)
      expect(build(:officer, role: "")).to be_valid
    end

    it "needs a unique role if it has one" do
      create(:officer, role: "women")
      expect(build(:officer, role: "women")).to_not be_valid
    end
  end

  context "contacts" do
    it "tidies the email and phone, and blanks become nil" do
      officer = create(:officer, email: " ratings@icu.ie ", phone: " 087  123 4567 ")
      expect(officer.email).to eq "ratings@icu.ie"
      expect(officer.phone).to eq "087 123 4567"
      expect(create(:officer, email: " ", phone: "").attributes.values_at("email", "phone")).to eq [nil, nil]
    end

    it "needs a valid email if it has one" do
      expect(build(:officer, email: "ratings at icu.ie")).to_not be_valid
    end

    it "obscures the email for the contacts page" do
      expect(create(:officer, email: "ratings@icu.ie").html_email).to start_with "<script>liame("
      expect(create(:officer).html_email).to be_nil
    end
  end
end
