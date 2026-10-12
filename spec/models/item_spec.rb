require 'rails_helper'

describe Item do
  context "duplicate_of?" do
    let(:sub) { create(:subscription_item) }
    let(:ent) { create(:entry_item) }

    it "items with different subclasses" do
      expect(sub.duplicate_of?(ent)).to be false
      expect(ent.duplicate_of?(sub)).to be false
    end
  end

  context "search by date" do
    let(:june_cart) { create(:cart, status: "paid", payment_completed: Time.zone.local(2026, 6, 2, 9)) }
    let(:sept_cart) { create(:cart, status: "paid", payment_completed: Time.zone.local(2026, 9, 30, 18)) }
    let!(:paid_in_june)      { create(:paid_entry_item, cart: june_cart, fee: create(:entry_fee, name: "Bunratty"), created_at: Time.zone.local(2026, 6, 1, 12)) }
    let!(:paid_in_september) { create(:paid_entry_item, cart: sept_cart, fee: create(:entry_fee, name: "Kilkenny"), created_at: Time.zone.local(2026, 6, 1, 12)) }
    let!(:unpaid)            { create(:entry_item, cart: create(:cart), fee: create(:entry_fee, name: "Galway"), created_at: Time.zone.local(2026, 9, 30, 18)) }

    def search(params)
      Item.search(params.merge(status: "", format: "csv"), nil).to_a
    end

    it "filters by the date added by default, including the whole of the last day" do
      expect(search(from_date: "2026-09-01", to_date: "2026-09-30")).to eq [unpaid]
      expect(search(from_date: "2026-06-01", to_date: "2026-06-01")).to contain_exactly(paid_in_june, paid_in_september)
    end

    it "filters by the date paid" do
      expect(search(date_type: "paid", from_date: "2026-09-01", to_date: "2026-09-30")).to eq [paid_in_september]
      expect(search(date_type: "paid", to_date: "2026-06-30")).to eq [paid_in_june]
    end

    it "ignores dates it can't parse" do
      expect(search(from_date: "not a date").size).to eq 3
    end
  end
end
