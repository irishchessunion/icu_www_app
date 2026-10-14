require 'rails_helper'

describe ApiKey do
  include_context "features"

  let(:name_label)    { I18n.t("api_key.name") }
  let(:access_events) { I18n.t("api_key.permission.events") }
  let(:new_key)       { "#new_api_key code" }

  context "authorization" do
    let!(:api_key) { create(:api_key) }

    let(:level1) { %w[admin] }
    let(:level2) { User::ROLES.reject { |role| level1.include?(role) }.append("guest") }

    it "level 1 can index, view, create and edit" do
      level1.each do |role|
        login role
        [admin_api_keys_path, admin_api_key_path(api_key), new_admin_api_key_path, edit_admin_api_key_path(api_key)].each do |path|
          visit path
          expect(page).to_not have_css(failure)
        end
      end
    end

    it "level 2 can't do anything" do
      level2.each do |role|
        login role
        [admin_api_keys_path, admin_api_key_path(api_key), new_admin_api_key_path, edit_admin_api_key_path(api_key)].each do |path|
          visit path
          expect(page).to have_css(failure, text: unauthorized)
        end
      end
    end
  end

  context "create" do
    before(:each) do
      login "admin"
      visit admin_api_keys_path
      click_link I18n.t("api_key.new")
    end

    it "shows the new key once" do
      fill_in name_label, with: "Chess Results"
      check access_events
      click_button save

      expect(page).to have_css(success, text: "created")
      expect(page).to have_css("h1", text: "Chess Results")

      expect(ApiKey.count).to eq 1
      api_key = ApiKey.first
      expect(api_key.name).to eq "Chess Results"
      expect(api_key.permissions).to eq "events"
      expect(api_key.active).to eq true

      key = find(new_key).text
      expect(ApiKey.authenticate(key)).to eq api_key
      expect(JournalEntry.where(journalable_type: "ApiKey", journalable_id: api_key.id, action: "create").count).to eq 1

      visit admin_api_key_path(api_key)
      expect(page).to_not have_css(new_key)
      expect(page).to_not have_text(key)
      expect(page).to have_css("code", text: api_key.key_prefix)

      visit admin_api_keys_path
      expect(page).to have_link("Chess Results")
      expect(page).to_not have_text(key)
    end

    it "without permissions" do
      fill_in name_label, with: "Chess Results"
      click_button save

      expect(page).to have_css(success, text: "created")
      expect(ApiKey.first.permissions).to be_nil
    end

    it "needs a name" do
      click_button save

      expect(page).to have_css(field_error, text: "blank")
      expect(ApiKey.count).to eq 0
    end
  end

  context "edit" do
    let!(:api_key) { create(:api_key, name: "Chess Results", permissions: "events") }

    before(:each) do
      login "admin"
      visit edit_admin_api_key_path(api_key)
    end

    it "remove permission and deactivate" do
      digest = api_key.key_digest
      expect(page).to have_checked_field(access_events)

      uncheck access_events
      uncheck active
      click_button save

      expect(page).to have_css(success, text: "updated")
      api_key.reload
      expect(api_key.permissions).to be_nil
      expect(api_key.active).to eq false
      expect(api_key.key_digest).to eq digest
    end

    it "rename" do
      fill_in name_label, with: "Chess Calendar"
      click_button save

      expect(page).to have_css("h1", text: "Chess Calendar")
      expect(api_key.reload.name).to eq "Chess Calendar"
    end
  end
end
