require 'rails_helper'

describe Officer do
  include_context "features"

  context "authorization" do
    let!(:admin)   { create(:officer, rank: 1, name: "Webmaster") }
    let!(:ratings) { create(:officer, rank: 2, name: "Rating Officer") }
    let!(:chair)   { create(:officer, rank: 3, name: "Chairperson") }
    let!(:vice)    { create(:officer, rank: 4, name: "Vice Chairperson") }
    let!(:pro)     { create(:officer, rank: 5, name: "Public Relations Officer") }

    let(:level1)   { %w[admin] }
    let(:level2)   { User::ROLES.reject { |role| level1.include?(role) }.append("guest") }

    let(:header)   { "h1" }

    it "level 1 can index, view, create and edit" do
      level1.each do |role|
        login role
        visit admin_officers_path
        expect(page).to_not have_css(failure)
        visit admin_officer_path(ratings)
        expect(page).to_not have_css(failure)
        expect(page).to have_css(header, text: "Rating Officer")
        expect(page).to have_link(edit, exact: true)
        visit edit_admin_officer_path(chair)
        expect(page).to_not have_css(failure)
        visit new_admin_officer_path
        expect(page).to_not have_css(failure)
      end
    end

    it "level 2 can't do anything" do
      level2.each do |role|
        login role
        visit admin_officers_path
        expect(page).to have_css(failure, text: unauthorized)
        visit admin_officer_path(ratings)
        expect(page).to have_css(failure, text: unauthorized)
        visit edit_admin_officer_path(chair)
        expect(page).to have_css(failure, text: unauthorized)
        visit new_admin_officer_path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end

  context "create" do
    let(:new_officer) { I18n.t("officer.new") }
    let(:role)        { I18n.t("officer.role") }
    let(:rank)        { I18n.t("officer.rank") }
    let(:executive)   { I18n.t("officer.exec") }
    let(:name)        { "Arbiters Officer" }

    before(:each) do
      login("admin")
      visit admin_officers_path
      click_link new_officer
    end

    it "success" do
      fill_in role, with: name
      fill_in rank, with: "15"
      uncheck executive
      click_button save

      expect(page).to have_css(success, text: "created")
      expect(page).to have_css("h1", text: name)

      expect(Officer.count).to eq 1
      officer = Officer.first
      expect(officer.name).to eq name
      expect(officer.rank).to eq 15
      expect(officer.executive).to eq false
      expect(officer.active).to eq true
      expect(officer.player).to be_nil
      expect(officer.role).to be_nil

      expect(JournalEntry.where(journalable_type: "Officer", journalable_id: officer.id, action: "create").count).to eq 1

      visit icu_officers_path
      expect(page).to have_css("td", text: "#{name}*")
    end

    it "duplicate name" do
      create(:officer, name: name)

      fill_in role, with: name
      click_button save

      expect(page).to have_css(field_error, text: "taken")
      expect(Officer.count).to eq 1
    end
  end

  context "edit" do
    let!(:officer) { create(:officer, name: "Arbitration Officer") }
    let(:role)     { I18n.t("officer.role") }

    it "rename" do
      login("admin")
      visit edit_admin_officer_path(officer)
      fill_in role, with: "Arbiters Officer"
      click_button save

      expect(page).to have_css(success, text: "updated")
      expect(page).to have_css("h1", text: "Arbiters Officer")
      expect(officer.reload.name).to eq "Arbiters Officer"
    end
  end
end
