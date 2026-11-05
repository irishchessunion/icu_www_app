require 'rails_helper'

describe "Items", type: :request do
  let(:player) { create(:player) }

  def item_params(fee)
    { item: { type: fee.subtype(:item), fee_id: fee.id, player_id: player.id } }
  end

  def sign_in(user)
    post sessions_path, params: { email: user.email, password: "password" }
  end

  context "a fee which is on sale" do
    let(:fee) { create(:entry_fee) }

    it "can be added to a cart" do
      get new_item_path(fee_id: fee.id)
      expect(response).to have_http_status(:ok)

      post items_path, params: item_params(fee)
      expect(response).to redirect_to cart_path
      expect(Item.pluck(:fee_id)).to eq [fee.id]
    end
  end

  context "a fee which is not on sale" do
    let(:inactive) { create(:entry_fee, active: false) }
    let(:finished) { create(:other_fee, sale_start: Date.today.days_ago(30), sale_end: Date.today.days_ago(1)) }

    it "can't be added to a cart" do
      [inactive, finished].each do |fee|
        get new_item_path(fee_id: fee.id)
        expect(response).to redirect_to shop_path

        post items_path, params: item_params(fee)
        expect(response).to redirect_to shop_path
      end
      expect(Item.count).to eq 0
    end
  end

  context "an organiser only fee" do
    let(:organiser) { create(:user, roles: "organiser") }
    let(:event)     { create(:event, user: organiser, subscription_required: false) }
    let(:fee)       { create(:entry_fee, event: event, organizer_only: true) }

    it "can't be added to a cart by a guest" do
      get new_item_path(fee_id: fee.id)
      expect(response).to redirect_to shop_path

      post items_path, params: item_params(fee)
      expect(response).to redirect_to shop_path
      expect(Item.count).to eq 0
    end

    it "can't be added to a cart by an ordinary member" do
      sign_in create(:user)

      get new_item_path(fee_id: fee.id)
      expect(response).to redirect_to shop_path

      post items_path, params: item_params(fee)
      expect(response).to redirect_to shop_path
      expect(Item.count).to eq 0
    end

    it "can be added to a cart by an organiser" do
      sign_in organiser

      get new_item_path(fee_id: fee.id)
      expect(response).to have_http_status(:ok)

      post items_path, params: item_params(fee)
      expect(response).to redirect_to cart_path
      expect(Item.pluck(:fee_id)).to eq [fee.id]
    end
  end
  context "a subscription with a made-up player" do
    let(:fee)    { create(:subscription_fee) }
    let(:newbie) { build(:new_player).to_json }

    def subscribe(player_id, player_data)
      post items_path, params: { item: { type: "Item::Subscription", fee_id: fee.id, player_id: player_id, player_data: player_data } }
    end

    it "is refused when the player doesn't exist, even with new player data" do
      subscribe(Player.maximum(:id).to_i + 1, newbie)
      expect(response).to have_http_status(:ok)
      expect(Item.count).to eq 0
    end

    it "is refused, not a crash, when the cart already has a subscription and the player data is junk" do
      subscribe(player.id, nil)
      expect(Item.count).to eq 1

      subscribe(nil, "01/01/1967")
      expect(response).to have_http_status(:ok)
      expect(Item.count).to eq 1
    end
  end

  context "an item type we don't sell" do
    let(:fee) { create(:subscription_fee) }

    it "is a bad request, not an error" do
      post items_path, params: { item: { type: "Item::Subscription6dMILQpV", fee_id: fee.id, player_id: player.id } }
      expect(response).to have_http_status(:bad_request)
      expect(Item.count).to eq 0
    end
  end
end
