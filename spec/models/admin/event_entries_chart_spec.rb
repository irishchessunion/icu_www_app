require 'rails_helper'

describe Admin::EventEntriesChart do
  let(:today) { Date.new(2026, 1, 8) }
  let(:event) { create(:event, sections: "A, B", subscription_required: false) }
  let(:standard) { create(:entry_fee, event: event, name: "Standard", amount: 50) }

  def chart(period = "day")
    described_class.new(event, period: period, today: today).data
  end

  def values(data, breakdown, name)
    data.fetch(:series).fetch(breakdown).find { |series| series[:name] == name }.fetch(:data)
  end

  it "counts paid entry items by section and fee, and sums their actual costs" do
    discounted = create(:entry_fee, event: event, name: "Discounted", amount: 30)
    cart = create(:cart, status: "paid", payment_completed: today.in_time_zone, total: 200)
    first = create(:paid_entry_item, fee: standard, section: "A", cart: cart, cost: 45)
    create(:paid_entry_item, fee: discounted, section: "B", cart: cart, player: first.player, cost: 25.50)
    create(:paid_entry_item, fee: standard, section: "B", cart: cart, cost: 30.25)
    %w[unpaid refunded].each { |status| create(:entry_item, fee: standard, section: "A", cart: cart, status: status) }

    data = chart
    expect(values(data, :section, "A").last).to eq 1
    expect(values(data, :section, "B").last).to eq 2
    expect(values(data, :fee, "Standard").last).to eq 2
    expect(values(data, :fee, "Discounted").last).to eq 1
    expect(values(data, :gross, "Gross").last).to eq 100.75
  end

  it "zero-fills the last fourteen days, twelve Monday-based weeks, and twelve months by payment date" do
    %w[2025-01-31 2025-02-01 2025-12-28 2025-12-29 2026-01-08 2026-01-09].each do |date|
      cart = create(:cart, status: "paid", payment_completed: Date.parse(date).in_time_zone)
      create(:paid_entry_item, fee: standard, section: "A", cart: cart, created_at: Date.new(2025, 1, 1))
    end

    data = chart
    expect(data[:categories].size).to eq 14
    expect(values(data, :section, "A")).to eq [0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]

    data = chart("week")
    expect(data[:categories].size).to eq 12
    expect(data[:categories].first).to eq "20 Oct"
    expect(data[:categories].last).to eq "5 Jan"
    expect(values(data, :section, "A")).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1]

    data = chart("month")
    expect(data[:categories].size).to eq 12
    expect(data[:categories].first).to eq "Feb25"
    expect(data[:categories].last).to eq "Jan26"
    expect(values(data, :section, "A")).to eq [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1]
  end
end
