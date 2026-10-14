require 'rails_helper'

describe Item do
  include_context "features"

  context "authorization" do
    let(:level1) { %w(admin auditor treasurer organiser) }
    let(:level2) { User::ROLES.reject { |r| level1.include?(r) } }
    let(:level3) { ["guest"] }

    it "level 1 can index items and show ledger" do
      level1.each do |role|
        login role
        visit admin_items_path
        expect(page).to_not have_css(failure)
        visit sales_ledger_admin_items_path
        expect(page).to_not have_css(failure)
      end
    end

    it "level 2 can show ledger" do
      level2.each do |role|
        login role
        visit admin_items_path
        expect(page).to have_css(failure, text: unauthorized)
        visit sales_ledger_admin_items_path
        expect(page).to_not have_css(failure)
      end
    end

    it "level 3 can do nothing" do
      level3.each do |role|
        login role
        visit admin_items_path
        expect(page).to have_css(failure, text: unauthorized)
        visit sales_ledger_admin_items_path
        expect(page).to have_css(failure, text: unauthorized)
      end
    end
  end

  context "searching by payment date" do
    let(:paid_cart) { create(:cart, status: "paid", payment_completed: Time.zone.local(2026, 9, 15, 10)) }
    let!(:item)     { create(:paid_entry_item, cart: paid_cart, created_at: Time.zone.local(2026, 6, 1, 12)) }

    before(:each) do
      login "treasurer"
      visit admin_items_path
    end

    it "finds an item added in June but paid in September" do
      fill_in "from_date", with: "2026-09-01"
      fill_in "to_date", with: "2026-09-30"
      click_button search
      expect(page).to have_css(warning, text: I18n.t("no_matches"))

      select I18n.t("item.date_type.paid"), from: "date_type"
      click_button search
      expect(page).to have_css("td", text: "2026-09-15")
      expect(page).to have_css("td", text: "2026-06-01")
    end
  end
  
  context "moving to another section" do
    let(:event)    { create(:event, sections: "Masters, Major, Minor", subscription_required: false) }
    let!(:masters) { create(:entry_fee, name: "Masters", event: event, sections: "Masters", amount: 60) }
    let(:major)    { create(:entry_fee, name: "Major", event: event, sections: "Major", amount: 50) }
    let!(:minor)   { create(:entry_fee, name: "Minor", event: event, sections: "Minor", amount: 50) }
    let(:item)     { create(:paid_entry_item, fee: major, section: "Major", cart: create(:cart)) }
    let(:fee_warning) { "div.section-fee-warning" }

    before(:each) do
      login "admin"
    end

    it "offers all the event's sections, not just the fee's" do
      visit edit_admin_item_path(item)
      expect(page).to have_select("item[section]", options: %w[Masters Major Minor], selected: "Major")

      select "Minor", from: "item[section]"
      click_button I18n.t("item.change_section")

      expect(item.reload.section).to eq "Minor"
    end

    it "rejects a section the event doesn't have" do
      page.driver.submit :put, admin_item_path(item), { item: { section: "Nonsense" } }
      expect(page).to have_css(failure, text: I18n.t("item.move.invalid_section"))
      expect(item.reload.section).to eq "Major"
    end

    it "warns before moving to a section with a different fee", js: true do
      visit edit_admin_item_path(item)
      expect(page).to_not have_css(fee_warning)

      select "Masters", from: "item[section]"
      expect(page).to have_css(fee_warning, text: "Masters €60.00")

      select "Minor", from: "item[section]"
      expect(page).to_not have_css(fee_warning)
    end
  end
end
