require 'rails_helper'

describe Item::Entry do
  context "relation to fee" do
    let(:item)   { create(:entry_item) }
    let!(:other) { create(:subscription_item) }

    it "copied attributes" do
      expect(item.description).to eq item.fee.description(:full)
      expect(item.start_date).to eq item.fee.start_date
      expect(item.end_date).to eq item.fee.end_date
      expect(item.cost).to eq item.fee.amount
    end

    it "reverse association" do
      expect(item.fee.items.size).to eq 1
      expect(item.fee.items.first).to eq item
    end
  end

  context "duplicates" do
    let(:bunratty)  { create(:entry_fee, name: "Bunratty") }
    let(:kilkenny)  { create(:entry_fee, name: "Kilkenny") }
    let(:player)    { create(:player) }
    let(:reyalp)    { create(:player) }
    let!(:item1)    { create(:paid_entry_item, fee: bunratty, player: player) }
    let!(:item2)    { create(:paid_entry_item, fee: kilkenny, player: reyalp) }

    it "not for the same player in the same tournament" do
      expect{create(:entry_item, fee: bunratty, player: player)}.to raise_error(/entered/)
      expect{create(:entry_item, fee: kilkenny, player: reyalp)}.to raise_error(/entered/)
    end

    it "different player or tournament" do
      expect{create(:entry_item, fee: bunratty, player: reyalp)}.to_not raise_error
      expect{create(:entry_item, fee: kilkenny, player: player)}.to_not raise_error
    end
  end

  context "inactive duplicates" do
    let(:bunratty)  { create(:entry_fee, name: "Bunratty") }
    let(:kilkenny)  { create(:entry_fee, name: "Kilkenny") }
    let(:player)    { create(:player) }
    let(:reyalp)    { create(:player) }
    let!(:item1)    { create(:entry_item, fee: bunratty, player: player) }
    let!(:item2)    { create(:entry_item, fee: kilkenny, player: reyalp) }

    it "are allowed" do
      expect{create(:entry_item, fee: bunratty, player: player)}.to_not raise_error
      expect{create(:entry_item, fee: kilkenny, player: reyalp)}.to_not raise_error
    end
  end

  context "#duplicate_of?" do
    let(:player1)   { create(:player) }
    let(:player2)   { create(:player) }
    let(:fee1)      { create(:entry_fee) }
    let(:fee2)      { create(:entry_fee, name: "Challengers") }
    let(:item1)     { create(:entry_item, fee: fee1, player: player1) }

    it "duplicates" do
      expect(create(:entry_item, fee: fee1, player: player1)).to be_duplicate_of(item1)
    end

    it "not duplicates" do
      expect(create(:entry_item, fee: fee1, player: player2)).to_not be_duplicate_of(item1)
      expect(create(:entry_item, fee: fee2, player: player1)).to_not be_duplicate_of(item1)
    end
  end

  context "rating constraints" do
    let(:fee)         { create(:entry_fee, min_rating: 1400, max_rating: 1800, name: "Major") }
    let(:p1400_under) { create(:player, latest_rating: 1399) }
    let(:p1400_exact) { create(:player, latest_rating: 1400) }
    let(:p1400_over)  { create(:player, latest_rating: 1401) }
    let(:p1800_under) { create(:player, latest_rating: 1799) }
    let(:p1800_exact) { create(:player, latest_rating: 1800) }
    let(:p1800_over)  { create(:player, latest_rating: 1801) }
    let(:p_no_rating) { create(:player, latest_rating: nil) }

    it "min rating" do
      expect{create(:entry_item, fee: fee, player: p1400_under)}.to raise_error(/under/)
      expect{create(:entry_item, fee: fee, player: p1400_exact)}.to_not raise_error
      expect{create(:entry_item, fee: fee, player: p1400_over)}.to_not raise_error
      expect{create(:entry_item, fee: fee, player: p_no_rating)}.to_not raise_error
    end

    it "max rating" do
      expect{create(:entry_item, fee: fee, player: p1800_under)}.to_not raise_error
      expect{create(:entry_item, fee: fee, player: p1800_exact)}.to_not raise_error
      expect{create(:entry_item, fee: fee, player: p1800_over)}.to raise_error(/over/)
      expect{create(:entry_item, fee: fee, player: p_no_rating)}.to_not raise_error
    end
  end

  context "player data" do
    it "blank" do
      item = build(:entry_item, player_data: "")
      expect(item).to be_valid
      expect(item.player_data).to be_nil
    end

    it "present" do
      item = build(:entry_item, player_data: "{}")
      expect(item).to_not be_valid
    end
  end

  context "moving sections" do
    let(:event)   { create(:event, sections: "Masters, Major, Minor", subscription_required: false) }
    let(:masters) { create(:entry_fee, name: "Masters", event: event, sections: "Masters", amount: 60) }
    let(:major)   { create(:entry_fee, name: "Major", event: event, sections: "Major", amount: 50) }
    let!(:minor)  { create(:entry_fee, name: "Minor", event: event, sections: "Minor", amount: 50) }
    let(:item)    { create(:paid_entry_item, fee: major, section: "Major") }

    it "can move to any of the event's sections, not just its fee's" do
      expect(item.movable_sections).to eq %w[Masters Major Minor]
    end

    it "flags only sections whose fees differ from what was paid" do
      masters
      expect(item.sections_with_different_fees).to eq("Masters" => [masters])
    end

    it "flags sections that no fee covers" do
      expect(item.sections_with_different_fees).to eq("Masters" => [])
    end

    it "doesn't count a fee without sections as covering a section" do
      masters
      open_fee = create(:entry_fee, name: "Open", event: event, amount: 50)
      open_fee.update_column(:sections, nil)
      unsectioned = create(:paid_entry_item, fee: open_fee, section: nil)
      expect(unsectioned.sections_with_different_fees.keys).to eq %w[Masters Major]
      expect(unsectioned.sections_with_different_fees["Masters"]).to eq [masters]
    end

    it "accepts a matching discounted amount" do
      masters.update!(discounted_amount: 50, discount_deadline: Date.today)
      expect(item.sections_with_different_fees).to be_empty
    end
  end
  context "players from outside Ireland" do
    let(:event)        { create(:event, subscription_required: true) }
    let(:fee)          { create(:entry_fee, event: event) }
    let!(:overseas)    { create(:subscription_fee, name: "Overseas", amount: 5.0, overseas: true) }
    let(:cart)         { create(:cart) }
    let(:newbie)       { build(:new_player, fed: "POL").to_json }

    def entry(attrs)
      Item::Entry.new({ fee: fee, cart: cart }.merge(attrs))
    end

    it "allows new players only if the event needs a subscription and there's an overseas one on sale" do
      expect(fee.new_player_allowed?).to be true
      expect(create(:entry_fee, name: "No event").new_player_allowed?).to be false
      overseas.update!(overseas: false)
      expect(Fee::Entry.find(fee.id).new_player_allowed?).to be false
    end

    it "gets the overseas subscription with a new player's entry, and the entry is then valid" do
      item = entry(player_data: newbie)
      expect(item).to_not be_valid

      subscription = item.overseas_subscription
      expect(subscription.fee).to eq overseas
      expect(subscription.player_data).to eq newbie
      subscription.save!
      expect(item).to be_valid
    end

    it "gets it for an existing player from outside Ireland who isn't subscribed, but not one who is" do
      player = create(:player, fed: "POL")
      expect(entry(player: player).overseas_subscription.player).to eq player

      create(:legacy_subscription_item, player: player, description: "Standard ICU Subscription #{Season.new}", end_date: Season.new.end)
      expect(entry(player: player).overseas_subscription).to be_nil
    end

    it "doesn't get it for an Irish player" do
      expect(entry(player_data: build(:new_player, fed: "IRL").to_json).overseas_subscription).to be_nil
      expect(entry(player: create(:player, fed: "IRL")).overseas_subscription).to be_nil
    end

    it "is linked to the player the subscription creates on payment" do
      item = entry(player_data: newbie)
      item.overseas_subscription.save!
      item.save!

      cart.items.each { |i| i.complete("cash") }
      player = Player.find_by!(last_name: JSON.parse(newbie)["last_name"])
      expect(item.reload.player).to eq player
      expect(Item::Subscription.last.player).to eq player
      expect(Player.where(last_name: player.last_name).count).to eq 1
    end

    it "treats entries for two different new players as different" do
      first = entry(player_data: newbie)
      first.overseas_subscription.save!
      first.save!
      other = entry(player_data: build(:new_player, fed: "POL").to_json)
      expect(cart.duplicates?(other)).to be false
      expect(cart.duplicates?(entry(player_data: newbie))).to be true
    end
  end
end
