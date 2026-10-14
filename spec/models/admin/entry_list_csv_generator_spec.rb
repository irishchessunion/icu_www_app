require 'rails_helper'

describe Admin::EntryListCsvGenerator do
  let(:paid_cart) { create(:cart, status: "paid", payment_completed: Time.zone.local(2026, 9, 15, 10, 30)) }
  let!(:paid)     { create(:paid_entry_item, cart: paid_cart, created_at: Time.zone.local(2026, 6, 1, 12)) }
  let!(:unpaid)   { create(:entry_item, cart: create(:cart), fee: create(:entry_fee, name: "Kilkenny")) }

  let(:rows) { CSV.parse(subject.generate_from_items(Item.order(:id), "test", show_paid_date: true)) }

  it "has the payment completion date after the date the item was created" do
    expect(rows[1].first(2)).to eq %w(Date Paid-Date)
    expect(rows[2].first(2)).to eq %w(2026-06-01 2026-09-15)
  end

  it "leaves the payment date blank for unpaid items" do
    expect(rows[3][1]).to be_nil
  end

  it "leaves out the payment date unless asked, so event entry downloads keep their columns" do
    rows = CSV.parse(subject.generate_from_items(Item.order(:id), "test"))
    expect(rows[1].first(2)).to eq %w(Date Description)
  end
end
