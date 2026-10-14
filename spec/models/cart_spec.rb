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
end
