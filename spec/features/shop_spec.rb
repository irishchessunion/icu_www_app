require 'spec_helper'

describe "Shop" do
  let(:add_to_cart)     { I18n.t("item.add") }
  let(:cart_link)       { I18n.t("shop.cart.current") + ":" }
  let(:cost)            { I18n.t("item.cost") }
  let(:first_name)      { I18n.t("player.first_name") }
  let(:item)            { I18n.t("item.item") }
  let(:last_name)       { I18n.t("player.last_name") }
  let(:member)          { I18n.t("member") }
  let(:reselect_member) { I18n.t("item.member.reselect") }
  let(:select_member)   { I18n.t("item.member.select") }
  let(:total)           { I18n.t("shop.cart.total") }

  let(:delete)          { "✘" }
  let(:failure)         { "div.alert-danger" }
  let(:force_submit)    { "\n" }

  def xpath(type, text, *txts)
    txts.reduce('//tr/%s[contains(.,"%s")]' % [type, text]) do |acc, txt|
      acc + '/following-sibling::%s[contains(.,"%s")]' % [type, txt]
    end
  end

  context "empty cart" do
    it "create before viewing" do
      expect(Cart.count).to eq 0

      visit cart_path
      expect(page).to have_xpath(xpath("th", item, member, cost))
      expect(page).to have_xpath(xpath("th", total, "0.00"))

      expect(Cart.count).to eq 1
    end
  end

  context "subscriptions" do
    let!(:player)         { create(:player, dob: 58.years.ago, joined: 30.years.ago) }
    let!(:player2)        { create(:player, dob: 30.years.ago, joined: 20.years.ago) }
    let!(:junior)         { create(:player, dob: 10.years.ago, joined: 2.years.ago) }
    let!(:oldie)          { create(:player, dob: 70.years.ago, joined: 50.years.ago) }
    let!(:standard_sub)   { create(:subscription_fee, name: "Standard", amount: 35.0) }
    let!(:unemployed_sub) { create(:subscription_fee, name: "Unemployed", amount: 20.0) }
    let!(:under_12_sub)   { create(:subscription_fee, name: "Under 12", amount: 20.0, max_age: 12) }
    let!(:over_65_sub)    { create(:subscription_fee, name: "Over 65", amount: 20.0, min_age: 65) }
    let(:lifetime_sub)    { create(:lifetime_subscription, player: player) }
    let(:existing_sub)    { create(:paid_subscription_item, player: player, fee: standard_sub) }

    let(:lifetime_error)  { I18n.t("item.error.subscription.lifetime_exists", member: player.name(id: true)) }
    let(:exists_error)    { I18n.t("item.error.subscription.already_exists", member: player.name(id: true), season: standard_sub.season.to_s) }
    let(:in_cart_error)   { I18n.t("item.error.subscription.already_in_cart", member: player.name(id: true), season: standard_sub.season.to_s) }
    let(:too_old_error)   { I18n.t("item.error.age.old", member: player.name, date: under_12_sub.age_ref_date.to_s, limit: under_12_sub.max_age) }
    let(:too_young_error) { I18n.t("item.error.age.young", member: player.name, date: over_65_sub.age_ref_date.to_s, limit: over_65_sub.min_age) }

    it "add", js: true do
      visit shop_path
      expect(page).to_not have_link(cart_link)
      click_link standard_sub.description

      expect(page).to_not have_button(add_to_cart)
      click_button select_member

      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit

      click_link player.id

      expect(page).to_not have_button(select_member)
      expect(page).to have_button(reselect_member)
      click_button add_to_cart

      expect(Cart.count).to eq 1
      expect(Item::Subscription.count).to eq 1
      expect(Item::Subscription.inactive.where(fee: standard_sub, player: player).count).to eq 1

      cart = Cart.last
      subscription = Item::Subscription.last

      expect(page).to have_xpath(xpath("th", item, member, cost))
      expect(page).to have_xpath(xpath("td", subscription.description, player.name(id: true), subscription.cost))
      expect(page).to have_xpath(xpath("th", total, standard_sub.amount))

      expect(subscription).to be_unpaid
      expect(subscription.cart).to eq cart
      expect(subscription.fee).to eq standard_sub
      expect(subscription.player).to eq player

      visit shop_path
      expect(page).to have_link(cart_link)
    end

    it "blocked by lifetime subscription", js: true do
      expect(lifetime_sub.player).to eq player

      visit shop_path
      click_link standard_sub.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to have_css(failure, text: lifetime_error)

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 0
    end

    it "blocked by existing subscription", js: true do
      expect(existing_sub.player).to eq player

      visit shop_path
      click_link standard_sub.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to have_css(failure, text: exists_error)

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 0
    end

    it "blocked by cart duplicate", js: true do
      visit shop_path
      click_link standard_sub.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to_not have_css(failure)

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 1

      visit shop_path
      click_link unemployed_sub.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to have_css(failure, text: in_cart_error)

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 1
    end

    it "too old", js: true do
      visit shop_path
      click_link under_12_sub.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to have_css(failure, text: too_old_error)

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 0

      click_button select_member
      fill_in last_name, with: junior.last_name + force_submit
      fill_in first_name, with: junior.first_name + force_submit
      click_link junior.id
      click_button add_to_cart

      expect(page).to_not have_css(failure)

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 1
    end

    it "too young", js: true do
      visit shop_path
      click_link over_65_sub.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to have_css(failure, text: too_young_error)

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 0

      click_button select_member
      fill_in last_name, with: oldie.last_name + force_submit
      fill_in first_name, with: oldie.first_name + force_submit
      click_link oldie.id
      click_button add_to_cart

      expect(page).to_not have_css(failure)

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 1
    end

    it "delete", js: true do
      visit shop_path
      click_link standard_sub.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to have_xpath(xpath("th", total, standard_sub.amount))

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 1

      visit shop_path
      click_link unemployed_sub.description
      click_button select_member
      fill_in last_name, with: player2.last_name + force_submit
      fill_in first_name, with: player2.first_name + force_submit
      click_link player2.id
      click_button add_to_cart

      expect(page).to have_xpath(xpath("th", total, standard_sub.amount + unemployed_sub.amount))

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 2

      click_link delete, match: :first
      confirm_dialog

      expect(page).to have_xpath(xpath("th", total, unemployed_sub.amount))

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 1

      click_link delete, match: :first
      confirm_dialog

      expect(page).to have_xpath(xpath("th", total, 0.0))

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 0
    end

    it "delete from other cart", js: true do
      visit shop_path
      click_link standard_sub.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(Cart.count).to eq 1
      expect(Item::Subscription.inactive.count).to eq 1

      cart = Cart.include_items.first
      item = cart.items.first
      other_cart = create(:cart)
      item.cart_id = other_cart.id
      item.save

      expect(cart.items.count).to eq 0
      expect(other_cart.items.count).to eq 1

      click_link delete, match: :first
      confirm_dialog

      expect(page).to have_link(cart_link)

      expect(Cart.count).to eq 2
      expect(Item::Subscription.inactive.count).to eq 1

      expect(cart.items.count).to eq 0
      expect(other_cart.items.count).to eq 1
    end
  end

  context "entries" do
    let!(:player)         { create(:player) }
    let!(:master)         { create(:player, latest_rating: 2400) }
    let!(:beginner)       { create(:player, latest_rating: 1000) }
    let!(:u16)            { create(:player, dob: Date.today.years_ago(15), joined: Date.today.years_ago(5)) }
    let!(:u10)            { create(:player, dob: Date.today.years_ago(9), joined: Date.today.years_ago(1)) }
    let!(:entry_fee)      { create(:entry_fee) }
    let!(:u1400_fee)      { create(:entry_fee, name: "Limerick U1400", max_rating: 1400) }
    let!(:premier_fee)    { create(:entry_fee, name: "Kilbunny Premier", min_rating: 2000) }
    let!(:junior_fee)     { create(:entry_fee, name: "Irish U16", max_age: 15, min_age: 13, age_ref_date: Date.today.months_ago(1)) }

    let(:too_high_error)  { I18n.t("item.error.rating.high", member: master.name, limit: u1400_fee.max_rating) }
    let(:too_low_error)   { I18n.t("item.error.rating.low", member: beginner.name, limit: premier_fee.min_rating) }
    let(:too_old_error)   { I18n.t("item.error.age.old", member: player.name, date: junior_fee.age_ref_date.to_s, limit: junior_fee.max_age) }
    let(:too_young_error) { I18n.t("item.error.age.young", member: u10.name, date: junior_fee.age_ref_date.to_s, limit: junior_fee.min_age) }

    it "add", js: true do
      visit shop_path
      expect(page).to_not have_link(cart_link)
      click_link entry_fee.description

      expect(page).to_not have_button(add_to_cart)
      click_button select_member

      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit

      click_link player.id

      expect(page).to_not have_button(select_member)
      expect(page).to have_button(reselect_member)
      click_button add_to_cart

      expect(Cart.count).to eq 1
      expect(Item::Entry.inactive.where(fee: entry_fee, player: player).count).to eq 1

      cart = Cart.last
      entry = Item::Entry.last

      expect(page).to have_xpath(xpath("th", item, member, cost))
      expect(page).to have_xpath(xpath("td", entry.description, player.name(id: true), entry.cost))
      expect(page).to have_xpath(xpath("th", total, entry.cost))

      visit shop_path
      expect(page).to have_link(cart_link)

      expect(cart).to be_unpaid
      expect(entry.cart).to eq cart
      expect(entry.fee).to eq entry_fee
      expect(entry.player).to eq player

      visit shop_path
      expect(page).to have_link(cart_link)
    end

    it "too strong", js: true do
      visit shop_path
      click_link u1400_fee.description
      click_button select_member
      fill_in last_name, with: master.last_name + force_submit
      fill_in first_name, with: master.first_name + force_submit
      click_link master.id
      click_button add_to_cart

      expect(page).to have_css(failure, text: too_high_error)

      click_button select_member
      fill_in last_name, with: beginner.last_name + force_submit
      fill_in first_name, with: beginner.first_name + force_submit
      click_link beginner.id
      click_button add_to_cart

      expect(page).to_not have_css(failure)

      expect(Cart.count).to eq 1
      expect(Item::Entry.inactive.count).to eq 1

      visit shop_path
      click_link u1400_fee.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to_not have_css(failure)

      expect(Cart.count).to eq 1
      expect(Item::Entry.inactive.count).to eq 2
    end

    it "too weak", js: true do
      visit shop_path
      click_link premier_fee.description
      click_button select_member
      fill_in last_name, with: beginner.last_name + force_submit
      fill_in first_name, with: beginner.first_name + force_submit
      click_link beginner.id
      click_button add_to_cart

      expect(page).to have_css(failure, text: too_low_error)

      click_button select_member
      fill_in last_name, with: master.last_name + force_submit
      fill_in first_name, with: master.first_name + force_submit
      click_link master.id
      click_button add_to_cart

      expect(page).to_not have_css(failure)

      expect(Cart.count).to eq 1
      expect(Item::Entry.inactive.count).to eq 1

      visit shop_path
      click_link premier_fee.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to_not have_css(failure)

      expect(Cart.count).to eq 1
      expect(Item::Entry.inactive.count).to eq 2
    end

    it "too old or young", js: true do
      visit shop_path
      click_link junior_fee.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      expect(page).to have_css(failure, text: too_old_error)

      click_button select_member
      fill_in last_name, with: u10.last_name + force_submit
      fill_in first_name, with: u10.first_name + force_submit
      click_link u10.id
      click_button add_to_cart

      expect(page).to have_css(failure, text: too_young_error)

      click_button select_member
      fill_in last_name, with: u16.last_name + force_submit
      fill_in first_name, with: u16.first_name + force_submit
      click_link u16.id
      click_button add_to_cart

      expect(page).to_not have_css(failure)

      expect(Cart.count).to eq 1
      expect(Item::Entry.inactive.count).to eq 1
    end
  end
end