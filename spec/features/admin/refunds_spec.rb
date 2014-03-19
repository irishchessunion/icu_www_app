require 'spec_helper'

describe "Refunds" do
  let(:player)                { create(:player) }

  let(:select_member)         { I18n.t("shop.cart.item.select_member") }
  let(:first_name)            { I18n.t("player.first_name") }
  let(:last_name)             { I18n.t("player.last_name") }
  let(:add_to_cart)           { I18n.t("shop.cart.item.add") }
  let(:checkout)              { I18n.t("shop.cart.checkout") }
  let(:continue)              { I18n.t("shop.cart.continue") }
  let(:pay)                   { I18n.t("shop.payment.card.pay") }
  let(:completed)             { I18n.t("shop.payment.completed") }

  let(:number_id)             { "number" }
  let(:month_id)              { "exp-month" }
  let(:year_id)               { "exp-year" }
  let(:email_id)              { "confirmation_email" }
  let(:name_id)               { "payment_name" }
  let(:cvc_id)                { "cvc" }

  let(:number)                { "4242 4242 4242 4242" }
  let(:mm)                    { "01" }
  let(:yyyy)                  { (Date.today.year + 2).to_s }
  let(:cvc)                   { "123" }
  let(:force_submit)          { "\n" }

  let(:title)                 { "h3" }
  let(:refund_link)           { "Refund..." }
  let(:refund_button)         { "Refund" }
  let(:total)                 { "//th[.='All']/following-sibling::th" }
  let(:success)               { "div.alert-success" }
  let(:refund_ok)             { "Refund was successful" }

  context "multiple items" do
    let!(:subscripsion_fee)  { create(:subscripsion_fee) }
    let!(:entri_fee)         { create(:entri_fee) }

    before(:each) do
      visit xshop_path

      click_link subscripsion_fee.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      click_link continue
      click_link entri_fee.description
      click_button select_member
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id
      click_button add_to_cart

      click_link checkout
      fill_in number_id, with: number
      select mm, from: month_id
      select yyyy, from: year_id
      fill_in cvc_id, with: cvc
      fill_in name_id, with: player.name
      fill_in email_id, with: player.email
      click_button pay

      expect(page).to have_css(title, text: completed)
    end

    after(:each) do
      ActionMailer::Base.deliveries.clear
    end

    it "refund separately", js: true do
      expect(Cart.count).to eq 1
      cart = Cart.include_items.last
      expect(cart).to be_paid
      expect(cart.items.size).to eq 2

      subscription = cart.items.detect { |item| item.type == "Item::Subscripsion" }
      entry = cart.items.detect { |item| item.type == "Item::Entri" }
      expect(subscription).to be_paid
      expect(entry).to be_paid

      expect(cart.total).to eq subscription.cost + entry.cost

      treasurer = login("treasurer")

      visit admin_carts_path
      click_link cart.id
      click_link refund_link

      expect(page).to have_xpath(total, text: "%.2f" % cart.total)

      check "item_#{subscription.id}"
      click_button refund_button
      confirm_dialog

      expect(page).to have_css(success, refund_ok)

      cart.reload
      subscription.reload
      entry.reload

      expect(cart).to be_part_refunded
      expect(cart.total).to eq entry.cost
      expect(subscription).to be_refunded
      expect(entry).to be_paid

      expect(cart.refunds.size).to eq 1
      refund = cart.refunds[0]
      expect(refund.error).to be_nil
      expect(refund.amount).to eq subscription.cost
      expect(refund.user).to eq treasurer

      click_link refund_link

      expect(page).to have_xpath(total, text: "%.2f" % cart.total)

      check "item_#{entry.id}"
      click_button refund_button
      confirm_dialog

      expect(page).to have_css(success, refund_ok)
      expect(page).to_not have_link(refund_button)

      cart.reload
      subscription.reload
      entry.reload

      expect(cart).to be_refunded
      expect(cart.total).to eq 0.0
      expect(subscription).to be_refunded
      expect(entry).to be_refunded

      expect(cart.refunds.size).to eq 2
      refund = cart.refunds[0]
      expect(refund.error).to be_nil
      expect(refund.amount).to eq entry.cost
      expect(refund.user).to eq treasurer
    end

    it "refunded together", js: true do
      expect(Cart.count).to eq 1
      cart = Cart.include_items.last
      expect(cart).to be_paid
      expect(cart.items.size).to eq 2

      subscription = cart.items.detect { |item| item.type == "Item::Subscripsion" }
      entry = cart.items.detect { |item| item.type == "Item::Entri" }
      expect(subscription).to be_paid
      expect(entry).to be_paid

      expect(cart.total).to eq subscription.cost + entry.cost

      treasurer = login("treasurer")

      visit admin_carts_path
      click_link cart.id
      click_link refund_link

      expect(page).to have_xpath(total, text: "%.2f" % cart.total)

      check "all_items"
      click_button refund_button
      confirm_dialog

      expect(page).to have_css(success, refund_ok)

      cart.reload
      subscription.reload
      entry.reload

      expect(cart).to be_refunded
      expect(cart.total).to eq 0.0
      expect(subscription).to be_refunded
      expect(entry).to be_refunded

      expect(cart.refunds.size).to eq 1
      refund = cart.refunds[0]
      expect(refund.error).to be_nil
      expect(refund.amount).to eq subscription.cost + entry.cost
      expect(refund.user).to eq treasurer
    end
  end
end