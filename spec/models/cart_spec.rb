require 'rails_helper'

describe Cart do
  context "#purchase" do
    let(:fee)    { create(:subscription_fee) }
    let(:cart)   { create(:cart) }
    let(:user)   { User::Guest.new }
    let(:params) { { payment_intent_id: "pi_3QMTIr9JTJmjex", confirmation_email: "mark@markorr.net", payment_name: "Mark Orr" } }
    let(:intent) { double(id: params[:payment_intent_id], amount: (fee.amount * 100).to_i, status: "succeeded", latest_charge: "ch_3QMTIr9JTJmjex") }

    before(:each) do
      create(:subscription_item, fee: fee, cart: cart)
      allow(Stripe::PaymentIntent).to receive(:retrieve).and_return(intent)
      allow(Stripe::PaymentIntent).to receive(:update)
    end

    after(:each) do
      ActionMailer::Base.deliveries.clear
    end

    it "a successful payment pays for the cart" do
      cart.purchase(params, user)

      expect(cart).to be_paid
      expect(cart.payment_ref).to eq intent.id
      expect(cart.items.map(&:status)).to eq ["paid"]
    end

    it "the cart is still paid for if the payment's description can't be updated" do
      allow(Stripe::PaymentIntent).to receive(:update).and_raise(Stripe::APIConnectionError.new("connection failed"))

      cart.purchase(params, user)

      expect(cart.reload).to be_paid
      expect(Failure.pluck(:name)).to eq ["UpdatePaymentIntentFailure"]
    end

    it "a payment can't be used for a second cart" do
      cart.purchase(params, user)
      other = create(:cart)
      create(:subscription_item, fee: fee, cart: other)

      other.purchase(params, user)

      expect(other.reload).to be_unpaid
      expect(other.items.map(&:status)).to eq ["unpaid"]
      expect(other.payment_errors.map(&:message)).to eq ["Something went wrong, please contact webmaster@icu.ie"]
    end
  end

  context "#purchase when another cart takes the same payment at the same time" do
    let(:fee)    { create(:subscription_fee) }
    let(:player) { create(:player) }
    let!(:user)  { create(:user, player: player, expires_on: Date.today.end_of_year) }
    let(:cart)   { create(:cart) }
    let(:other)  { create(:cart, status: "paid", payment_method: "stripe") }
    let(:params) { { payment_intent_id: "pi_3QMTIr9JTJmjex", confirmation_email: "mark@markorr.net", payment_name: "Mark Orr" } }
    let(:intent) { double(id: params[:payment_intent_id], amount: (fee.amount * 100).to_i, status: "succeeded", latest_charge: "ch_3QMTIr9JTJmjex") }

    before(:each) do
      create(:subscription_item, fee: fee, player: player, cart: cart)
      allow(Stripe::PaymentIntent).to receive(:retrieve).and_return(intent)
      # This is called after the check for a payment already used, so it's where the other request can get in first.
      allow(Stripe::PaymentIntent).to receive(:update) { other.update_column(:payment_ref, intent.id) }
    end

    it "leaves the cart, its items and the member's subscription as they were" do
      cart.purchase(params, User::Guest.new)

      expect(cart).to be_unpaid
      expect(cart.reload).to be_unpaid
      expect(cart.payment_ref).to be_nil
      expect(cart.items.map(&:status)).to eq ["unpaid"]
      expect(user.reload.expires_on).to eq Date.today.end_of_year
      expect(cart.payment_errors.map(&:message)).to eq ["Something went wrong, please contact webmaster@icu.ie"]
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  context "#refund" do
    let(:fee)   { create(:subscription_fee) }
    let(:user)  { create(:user) }
    let(:cart)  { create(:cart, status: "paid", payment_method: "stripe", payment_ref: "pi_3QMTIr9JTJmjex", payment_account: account, total: fee.amount, original_total: fee.amount) }
    let!(:item) { create(:paid_subscription_item, fee: fee, cart: cart) }

    context "a cart paid for with an old Stripe account" do
      let(:account) { "pk_live_an_old_account" }

      it "is revoked without asking Stripe to send the money back" do
        expect(Stripe::PaymentIntent).to_not receive(:retrieve)
        expect(Stripe::Refund).to_not receive(:create)

        refund = cart.refund([item.id], user)

        expect(refund.error).to be_nil
        expect(refund.automatic).to be false
        expect(refund.amount).to eq fee.amount
        expect(cart.reload).to be_refunded
        expect(item.reload).to be_refunded
      end
    end

    context "a cart paid for with the current Stripe account" do
      let(:account) { Cart.current_payment_account }
      let(:intent)  { double(id: cart.payment_ref, amount: (fee.amount * 100).to_i, latest_charge: "ch_3QMTIr9JTJmjex") }

      it "is refunded through Stripe" do
        allow(Stripe::PaymentIntent).to receive(:retrieve).and_return(intent)
        allow(Stripe::Charge).to receive(:retrieve).and_return(double(amount_refunded: 0))
        expect(Stripe::Refund).to receive(:create).with({ payment_intent: intent.id, amount: intent.amount }).and_return(double(status: "succeeded"))

        refund = cart.refund([item.id], user)

        expect(refund.error).to be_nil
        expect(refund.automatic).to be true
        expect(cart.reload).to be_refunded
        expect(item.reload).to be_refunded
      end
    end
  end
end
