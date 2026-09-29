require 'rails_helper'

describe "Payment receipt sign-up link" do
  let(:player)       { create(:player) }
  let(:subscription) { create(:paid_subscription_item, player: player) }
  let(:cart)         { create(:cart, status: "paid", payment_method: "stripe", payment_completed: Time.now, total: 35.0, confirmation_email: "payer@example.com") }
  let(:text)         { IcuMailer.payment_receipt(cart.id).body.decoded }
  let(:ticket)       { subscription.season_ticket }

  before(:each) do
    subscription.update_column(:cart_id, cart.id)
  end

  def link(params)
    "http://www.icu.ie/sign_up?#{params.to_query}"
  end

  it "prefills the ICU ID, season ticket and player's email for a player without a user account" do
    expect(ticket).to be_present
    expect(text).to include("#{player.name(id: true)}: #{link(email: player.email, player_id: player.id, ticket: ticket)}")
  end

  it "falls back to the payer's email when the player has none" do
    player.update_column(:email, nil)
    expect(text).to include(link(email: "payer@example.com", player_id: player.id, ticket: ticket))
  end

  it "omits an email that another user account already has" do
    create(:user, email: player.email)
    create(:user, email: "payer@example.com")
    expect(text).to include(link(player_id: player.id, ticket: ticket))
  end

  it "has no link when the player already has a user account" do
    create(:user, player: player)
    expect(text).to_not include("sign_up")
  end

  it "has no link for a refunded subscription" do
    subscription.update_column(:status, "refunded")
    expect(text).to_not include("sign_up")
  end
end
