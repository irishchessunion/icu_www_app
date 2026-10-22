require 'rails_helper'

describe "Entering an event", js: true do
  include_context "features"

  let(:event)     { create(:event, subscription_required: true) }
  let(:fee)       { create(:entry_fee, event: event) }
  let!(:overseas) { create(:subscription_fee, name: "Overseas", amount: 5.0, overseas: true) }
  let(:new_overseas) { I18n.t("item.member.new_overseas") }

  it "as a new player from outside Ireland adds the overseas subscription to the cart with the entry" do
    newbie = build(:new_player, fed: "POL")
    visit new_item_path(fee_id: fee.id)
    expect(page).to have_content(overseas.description(:full))
    expect(page).to_not have_content(/profile/i)

    click_button new_overseas
    within "#new_player_modal" do
      fill_in I18n.t("player.last_name"), with: newbie.last_name
      fill_in I18n.t("player.first_name"), with: newbie.first_name
      fill_in I18n.t("player.birthdate.label"), with: newbie.dob.to_s
      select I18n.t("player.gender.M"), from: I18n.t("player.gender.gender")
      select ICU::Federation.find("POL").name, from: I18n.t("player.federation")
      click_button I18n.t("save")
    end
    expect(page).to have_css("#player_name", text: newbie.last_name)
    click_button I18n.t("item.add")

    expect(page).to have_current_path(cart_path)
    expect(Item::Entry.last.player_data).to be_present
    expect(Item::Subscription.last.fee).to eq overseas
    expect(page).to have_content(overseas.description(:full))
    expect(page).to have_content(fee.description(:full))
  end

  it "searches for a player while typing, without leaving the field (as iPhones don't)" do
    player = create(:player, last_name: "Bosch")
    visit new_item_path(fee_id: create(:entry_fee, name: "Open").id)
    click_button I18n.t("item.member.select")
    find("#player_ids_form #last_name").send_keys("Bosch")
    expect(page).to have_css("#player_ids_results", text: player.first_name)
  end
end
