require 'rails_helper'

describe "Pay", js: true do
  include_context "features"

  let(:add_to_cart)           { I18n.t("item.add") }
  # let(:bad_cvc)               { I18n.t("shop.payment.error.cvc") }
  let(:bad_cvc)               { "Your card’s security code is incomplete." }
  let(:bad_email)             { I18n.t("shop.payment.error.email") }
  # let(:bad_expiry)            { I18n.t("shop.payment.error.expiry") }
  let(:bad_expiry)            { "Your card’s expiry date is incomplete" }
  let(:bad_name)              { I18n.t("shop.payment.error.name") }
  # let(:bad_number)            { I18n.t("shop.payment.error.number") }
  let(:bad_number)            { "Your card number is incomplete" }
  let(:checkout)              { I18n.t("shop.cart.checkout") }
  let(:cheque)                { I18n.t("shop.payment.method.cheque") }
  let(:completed)             { I18n.t("shop.payment.completed") }
  let(:confirmation_email_to) { I18n.t("shop.payment.confirmation_sent.success") }
  let(:current)               { I18n.t("shop.cart.current") }
  let(:dob)                   { I18n.t("player.birthdate.label") }
  let(:fed)                   { I18n.t("player.federation") }
  let(:first_name)            { I18n.t("player.first_name") }
  let(:gateway)               { I18n.t("shop.payment.error.gateway") }
  let(:gender)                { I18n.t("player.gender.gender") }
  let(:last_name)             { I18n.t("player.last_name") }
  let(:new_member)            { I18n.t("item.member.new") }
  let(:pay)                   { I18n.t("shop.payment.card.pay") }
  let(:payer_email)           { I18n.t("shop.payment.offline.email") }
  let(:payer_first_name)      { I18n.t("shop.payment.offline.first_name") }
  let(:payer_last_name)       { I18n.t("shop.payment.offline.last_name") }
  let(:payer_method)          { I18n.t("shop.payment.offline.method") }
  let(:payment_received)      { I18n.t("shop.payment.received") }
  let(:payment_registered)    { I18n.t("shop.payment.registered") }
  let(:payment_time)          { I18n.t("shop.payment.time") }
  let(:season_ticket)         { I18n.t("user.ticket") }
  let(:select_member)         { I18n.t("item.member.select") }
  let(:shop)                  { I18n.t("shop.shop") }
  let(:total)                 { I18n.t("shop.cart.total") }

  let(:cvc_id)    { "Field-cvcInput" }
  let(:email_id)  { "confirmation_email" }
  let(:expiry_id) { "Field-expiryInput" }
  let(:name_id)   { "name" }
  let(:number_id) { "Field-numberInput" }

  let(:cvc)     { "123" }
  let(:expiry)  { "01 / #{((Date.today.year + 2).to_s)[2..4]}" }
  let(:number)  { "4000 0027 6000 3184" }
  let(:stripe)  { "stripe" }
  let(:account) { Cart.current_payment_account }

  let(:card_declined) { "Your card has been declined." }
  let(:expired_card)  { "Your card has expired. Try a different card." }
  let(:incorrect_cvc) { "Your card’s CVC is incorrect." }

  let(:item)    { "li" }
  let(:title)   { "h3" }

  let(:player)            { create(:player) }
  let!(:subscription_fee) { create(:subscription_fee) }
  let(:user)              { create(:user) }

  def add_something_to_cart
    visit shop_path
    wait_a_second(0.1)
    click_link subscription_fee.description
    click_button select_member
    wait_a_second(0.1)
    fill_in last_name, with: player.last_name + force_submit
    fill_in first_name, with: player.first_name + force_submit
    click_link player.id.to_s
    click_button add_to_cart
  end

  def fill_in_all_and_click_pay(opt = {})
    opt.reverse_merge!(number: number, expiry: expiry, cvc: cvc, name: player.name, email: player.email)
    within_frame do
      fill_in number_id, with: opt[:number] if opt[:number]
      fill_in expiry_id, with: opt[:expiry] if opt[:expiry]
      fill_in cvc_id, with: opt[:cvc]       if opt[:cvc]
    end
    fill_in name_id, with: opt[:name]     if opt[:name]
    fill_in email_id, with: opt[:email]   if opt[:email]
    click_button pay
    if opt[:number] == number
      # 3D secure, the button is in 2 nested iframes
      wait_a_second(5)
      within_frame(0) do
        within_frame(0) do
          page.find('#test-source-authorize-3ds').native.send_key(:enter)
        end
      end
    end
  end

  def fill_in_number_and_click_pay(number)
    within_frame do
      fill_in number_id, with: number
    end
    click_button pay
  end

  def gateway_error(text)
    "#{gateway}: \"#{text}\""
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  context "with card" do
    before(:each) do
      add_something_to_cart
      click_link checkout
      wait_a_second(2)
    end

    it "successful" do
      cart = Cart.last
      expect(cart).to be_unpaid
      expect(cart.payment_completed).to be_nil
      expect(cart.payment_ref).to be_nil
      expect(cart.payment_method).to be_nil
      expect(cart.payment_account).to be_nil
      expect(cart.user).to be_nil
      expect(cart.items.count).to eq 1
      
      subscription = cart.items.first
      expect(subscription).to be_unpaid
      expect(subscription.payment_method).to be_nil
      expect(subscription.source).to eq "www2"
      
      fill_in_all_and_click_pay
      
      expect(page).to have_css(title, text: completed)
      expect(page).to have_css(item, text: /\A#{total}: €#{"%.2f" % subscription.cost}\z/)
      expect(page).to have_css(item, text: /\A#{payment_time}: 20\d\d-\d\d-\d\d \d\d:\d\d GMT\z/)
      expect(page).to have_css(item, text: /\A#{confirmation_email_to}: #{player.email}\z/)
      
      cart.reload
      expect(cart).to be_paid
      expect(cart.user).to be_nil
      expect(cart.payment_completed).to be_present
      expect(cart.payment_ref).to be_present
      expect(cart.payment_method).to eq stripe
      expect(cart.payment_account).to eq account
      expect(cart.payment_errors.count).to eq 0
      expect(cart.confirmation_sent).to be true
      expect(cart.confirmation_error).to be_nil
      expect(cart.confirmation_text).to be_present
      
      subscription.reload
      expect(subscription).to be_paid
      expect(subscription.payment_method).to eq stripe
      
      expect(ActionMailer::Base.deliveries.size).to eq 1
      email = ActionMailer::Base.deliveries.last
      expect(email.from.size).to eq 1
      expect(email.from.first).to eq IcuMailer::FROM
      expect(email.to.size).to eq 1
      expect(email.to.first).to eq player.email
      expect(email.subject).to eq IcuMailer::CONFIRMATION
      
      text = email.body.decoded
      expect(text).to include(player.name(id: true))
      expect(text).to include("%.2f" % subscription.cost)
      expect(text).to include("#{season_ticket}: #{SeasonTicket.new(player.id, subscription.end_date.at_end_of_year).to_s}")
      expect(text).to eq cart.confirmation_text
    end

    it "stripe errors" do
      fill_in_all_and_click_pay(number: "4000000000000002")
      wait_a_second(2)
      expect(page).to have_css(failure, text: card_declined)
      subscription = Item::Subscription.last
      expect(subscription).to be_unpaid
      wait_a_second(0.5)
      cart = Cart.include_errors.last
      expect(cart).to be_unpaid
      expect(cart.user).to be_nil
      expect(cart.payment_errors.count).to eq 1
      payment_error = cart.payment_errors.last
      expect(payment_error.message).to eq card_declined
      expect(payment_error.details).to be_present
      expect(payment_error.payment_name).to eq player.name
      expect(payment_error.confirmation_email).to eq player.email
      expect(ActionMailer::Base.deliveries).to be_empty
      
      fill_in_number_and_click_pay(number: "4000000000000069")
      wait_a_second(2)
      expect(page).to have_css(failure, text: expired_card)
      subscription.reload
      expect(subscription).to be_unpaid
      cart.reload
      expect(cart).to be_unpaid
      expect(cart.user).to be_nil
      expect(cart.payment_errors.count).to eq 2
      payment_error = cart.payment_errors.last
      expect(payment_error.message).to eq expired_card
      expect(payment_error.details).to be_present
      expect(payment_error.payment_name).to eq player.name
      expect(payment_error.confirmation_email).to eq player.email
      expect(ActionMailer::Base.deliveries).to be_empty
      
      login(user)
      click_link shop
      click_link current
      click_link checkout
      
      fill_in_all_and_click_pay(number: "4000000000000127")
      wait_a_second(2)
      expect(page).to have_css(failure, text: incorrect_cvc)
      subscription.reload
      expect(subscription).to be_unpaid
      cart.reload
      expect(cart).to be_unpaid
      # expect(cart.user).to eq user
      expect(cart.user).to be_nil
      expect(cart.payment_errors.count).to eq 3
      payment_error = cart.payment_errors.last
      expect(payment_error.message).to eq incorrect_cvc
      expect(payment_error.details).to be_present
      expect(payment_error.payment_name).to eq player.name
      expect(payment_error.confirmation_email).to eq player.email
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "client side errors" do
      expect(PaymentError.count).to eq 0
      iframe = find('iframe')
      wait_a_second(3)

      fill_in name_id, with: player.name

      # Email.
      click_button pay
      expect(page).to have_css(failure, text: bad_email)
      fill_in email_id, with: "rubbish"
      click_button pay
      expect(page).to have_css(failure, text: bad_email)
      fill_in email_id, with: Faker::Internet.email

      # Card.
      click_button pay
      expect(page).to have_css(failure, text: bad_number)

      within_frame(iframe) do
        fill_in number_id, with: "1234"
      end
      click_button pay
      expect(page).to have_css(failure, text: bad_number)

      # Expiry.
      within_frame(iframe) do
        fill_in number_id, with: number
      end
      click_button pay
      expect(page).to have_css(failure, text: bad_expiry)
      within_frame(iframe) do
        fill_in expiry_id, with: "99"
      end
      click_button pay
      expect(page).to have_css(failure, text: bad_expiry)

      # CVC.
      within_frame(iframe) do
        fill_in expiry_id, with: expiry
      end
      click_button pay
      expect(page).to have_css(failure, text: bad_cvc)
      within_frame(iframe) do
        fill_in cvc_id, with: "1"
      end
      click_button pay
      expect(page).to have_css(failure, text: bad_cvc)

      # Name.
      within_frame(iframe) do
        fill_in cvc_id, with: cvc
      end
      find("#%s" % [name_id]).native.clear
      click_button pay
      expect(page).to have_css(failure, text: bad_name)

      wait_a_second(0.01) # allows time for ActiveRecord to populate the last PaymentError

      expect(PaymentError.count).to eq 6
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  context "with cash" do
    before(:each) do
      add_something_to_cart
    end

    it "successful" do
      expect(page).to have_link(checkout)
      expect(page).to_not have_link(payment_received)

      officer = login("membership")
      visit cart_path
      expect(page).to have_link(checkout)
      click_link payment_received

      fill_in payer_first_name, with: player.first_name
      fill_in payer_last_name, with: player.last_name
      select cheque, from: payer_method
      fill_in payer_email, with: player.email
      click_button confirm

      expect(page).to have_css(success, text: payment_registered)

      cart = Cart.last
      expect(cart).to be_paid
      expect(cart.payment_completed).to be_present
      expect(cart.payment_ref).to be_nil
      expect(cart.payment_method).to eq "cheque"
      expect(cart.payment_account).to be_nil
      expect(cart.user).to eq officer
      expect(cart.payment_errors.count).to eq 0
      expect(cart.items.count).to eq 1
      expect(cart.confirmation_sent).to be true
      expect(cart.confirmation_error).to be_nil
      expect(cart.confirmation_text).to be_present

      subscription = cart.items.first
      expect(subscription).to be_paid
      expect(subscription.payment_method).to eq "cheque"
      expect(subscription.source).to eq "www2"

      expect(ActionMailer::Base.deliveries.size).to eq 1
      email = ActionMailer::Base.deliveries.last
      expect(email.from.size).to eq 1
      expect(email.from.first).to eq IcuMailer::FROM
      expect(email.to.size).to eq 1
      expect(email.to.first).to eq player.email
      expect(email.subject).to eq IcuMailer::CONFIRMATION

      text = email.body.decoded
      expect(text).to include(player.name(id: true))
      expect(text).to include("%.2f" % subscription.cost)
      expect(text).to include("#{season_ticket}: #{SeasonTicket.new(player.id, subscription.end_date.at_end_of_year).to_s}")
      expect(text).to eq cart.confirmation_text
    end

    it "without email" do
      login("membership")
      visit cart_path
      click_link payment_received

      fill_in payer_first_name, with: player.first_name
      fill_in payer_last_name, with: player.last_name
      select cheque, from: payer_method
      click_button confirm

      expect(page).to have_css(success, text: payment_registered)

      cart = Cart.last
      expect(cart).to be_paid
      expect(cart.confirmation_sent).to be false
      expect(cart.confirmation_error).to eq "no email address available"
      expect(cart.confirmation_text).to be_present

      expect(ActionMailer::Base.deliveries.size).to eq 0

      text = cart.confirmation_text
      expect(text).to include(player.name(id: true))
      expect(text).to include("%.2f" % cart.total)
    end
  end

  context "new member" do
    let(:newbie)     { create(:new_player) }
    let(:newbie_fed) { ICU::Federation.find(newbie.fed).name }
    let(:newbie_sex) { I18n.t("player.gender.#{newbie.gender}") }

    before(:each) do
      visit shop_path
      click_link subscription_fee.description
      click_button new_member
      wait_a_second(0.1)
      fill_in last_name, with: newbie.last_name
      fill_in first_name, with: newbie.first_name
      fill_in dob, with: newbie.dob.to_s
      select newbie_sex, from: gender
      select newbie_fed, from: fed
      fill_in email, with: newbie.email
      click_button save
      expect(page).to_not have_css(failure)
      click_button add_to_cart
      click_link checkout
    end

    it "successful" do
      subscription = Item::Subscription.last
      expect(subscription.player_id).to be_nil
      expect(subscription.player_data).to be_present
      
      fill_in_all_and_click_pay
      
      expect(page).to have_css(title, text: completed)
      subscription.reload
      expect(subscription).to be_paid
      
      new_player = subscription.player
      expect(new_player).to be_present
      expect(new_player.first_name).to eq newbie.first_name
      expect(new_player.last_name).to eq newbie.last_name
      expect(new_player.dob).to eq newbie.dob
      expect(new_player.fed).to eq newbie.fed
      expect(new_player.gender).to eq newbie.gender
      expect(new_player.email).to eq newbie.email
      expect(new_player.status).to eq "active"
      expect(new_player.source).to eq "subscription"
      
      expect(ActionMailer::Base.deliveries.size).to eq 1
      email = ActionMailer::Base.deliveries.last
      
      text = email.body.decoded
      expect(text).to include(new_player.name(id: true))
      expect(text).to include("%.2f" % subscription.cost)
      expect(text).to include("#{season_ticket}: #{SeasonTicket.new(new_player.id, subscription.end_date.at_end_of_year).to_s}")
    end
  end

  context "user updates" do
    let!(:old_user) { create(:user, expires_on: Season.new.last.end_of_grace_period, player: player) }

    before(:each) do
      login("membership")
      visit shop_path
      click_link subscription_fee.description
      click_button select_member
      wait_a_second(0.1)
      fill_in last_name, with: player.last_name + force_submit
      fill_in first_name, with: player.first_name + force_submit
      click_link player.id.to_s
      click_button add_to_cart
    end

    it "card" do
      click_link checkout
      fill_in_all_and_click_pay
      
      expect(page).to have_css(title, text: completed)
      
      expect(Item::Subscription.count).to eq 1
      subscription = Item::Subscription.first
      expect(subscription).to be_paid
      expect(subscription.player_id).to eq player.id
      
      old_user.reload
      expect(old_user.expires_on).to eq Season.new.end_of_grace_period
    end

    it "cash" do
      click_link payment_received

      fill_in payer_first_name, with: player.first_name
      fill_in payer_last_name, with: player.last_name
      select cheque, from: payer_method
      fill_in payer_email, with: player.email
      click_button confirm

      expect(page).to have_css(success, text: payment_registered)

      expect(Item::Subscription.count).to eq 1
      subscription = Item::Subscription.first
      expect(subscription).to be_paid
      expect(subscription.player_id).to eq player.id

      old_user.reload
      expect(old_user.expires_on).to eq Season.new.end_of_grace_period
    end
  end
end
