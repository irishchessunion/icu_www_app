require 'rails_helper'

describe "Arbiters" do
  include_context "features"

  let(:level)          { I18n.t("arbiter.level") }
  let(:date_of_qual)   { I18n.t("arbiter.date_of_qualification") }
  let(:location_label) { I18n.t("arbiter.location") }

  before(:all) do
    @player  = create(:player, first_name: "Henry", last_name: "Williams")
    @arbiter = create(:arbiter, player: @player, level: "national", date_of_qualification: Date.new(2024, 6, 1), location: "Dublin")
  end

  after(:all) do
    @arbiter.destroy
    @player.destroy
  end

  context "admin" do
    before(:each) { login("admin") }

    it "lists all arbiters including inactive" do
      visit arbiters_path
      expect(page).to have_content("Henry Williams")
      expect(page).to have_content(I18n.t("arbiter.levels.national"))
    end

    it "displays arbiter details" do
      visit arbiter_path(@arbiter)
      expect(page).to have_content("Henry Williams")
      expect(page).to have_content(I18n.t("arbiter.levels.national"))
      expect(page).to have_content("2024-06-01")
      expect(page).to have_content("Dublin")
      expect(page).to have_link(I18n.t("edit"))
      expect(page).to have_link(I18n.t("delete"))
    end

    it "updates an arbiter" do
      visit edit_arbiter_path(@arbiter)
      fill_in location_label, with: "Cork"
      click_button save

      expect(page).to have_css(success, text: updated)
      expect(@arbiter.reload.location).to eq "Cork"

      @arbiter.update!(location: "Dublin") # restore
    end

    it "adds a new arbiter" do
      new_player = create(:player, first_name: "Alice", last_name: "Murphy")

      visit new_arbiter_path
      fill_in I18n.t("player.id"), with: new_player.id
      select I18n.t("arbiter.levels.fide"), from: level
      fill_in date_of_qual, with: "2025-03-01"
      click_button save

      expect(page).to have_css(success, text: created)
      expect(Arbiter.find_by(player_id: new_player.id)).to be_present
    end

    it "deletes an arbiter" do
      temp_player  = create(:player)
      temp_arbiter = create(:arbiter, player: temp_player)

      visit arbiter_path(temp_arbiter)
      click_link delete

      expect(page).to have_css(success, text: deleted)
      expect(Arbiter.find_by(id: temp_arbiter.id)).to be_nil
    end
  end

  context "player editing own record" do
    before(:each) do
      @user = login("member")
      @user.update!(player: @player)
    end

    it "can edit own contact details" do
      visit edit_arbiter_path(@arbiter)
      fill_in location_label, with: "Galway"
      click_button save

      expect(page).to have_css(success, text: updated)
      expect(@arbiter.reload.location).to eq "Galway"

      @arbiter.update!(location: "Dublin") # restore
    end

    it "cannot edit another player's record" do
      other_arbiter = create(:arbiter)
      visit edit_arbiter_path(other_arbiter)
      expect(page).to have_css(failure)
    end

    it "does not see admin-only fields on the edit form" do
      visit edit_arbiter_path(@arbiter)
      expect(page).not_to have_field(I18n.t("player.id"))
      expect(page).not_to have_select(level)
    end
  end

  context "public index" do
    it "lists active arbiters without login" do
      logout
      visit arbiters_path
      expect(page).to have_content("Henry Williams")
      expect(page).to have_content(I18n.t("arbiter.levels.national"))
    end
  end
end
