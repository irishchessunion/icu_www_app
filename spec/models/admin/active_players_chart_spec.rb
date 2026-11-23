require 'rails_helper'

describe Admin::ActivePlayersChart do
  let(:today) { Date.new(2026, 11, 23) }
  let(:current_fee) { create(:subscription_fee, years: "2026-27") }
  let(:previous_fee) { create(:subscription_fee, years: "2025-26") }

  def subscribe(player = create(:player), fee: current_fee, **attributes)
    create(:paid_subscription_item, player: player, fee: fee, created_at: fee.start_date.in_time_zone, **attributes)
  end

  def counts(period = "month", columns: 4)
    described_class.new(period: period, today: today).data.fetch(:series).transform_values do |series|
      series.to_h { |entry| [entry[:name], entry[:data].last(columns)] }
    end
  end

  it "counts presales in the purchased season" do
    returning, first_time = create_list(:player, 2)
    subscribe(returning, fee: previous_fee)
    subscribe(first_time, fee: previous_fee, status: "refunded")
    presale = Time.zone.local(2026, 8, 10)
    cart = create(:cart, status: "paid", payment_completed: presale)
    [returning, first_time].each { |player| subscribe(player, cart: cart, created_at: presale) }

    expect(counts[:membership]).to include("New Members" => [1, 1, 1, 1], "Renewed Members" => [0, 1, 1, 1])
    expect(counts("season", columns: 2)[:membership]).to include("New Members" => [1, 1], "Renewed Members" => [0, 1])
  end

  it "counts late renewals once paid" do
    returning = create(:player)
    create(:legacy_subscription_item, player: returning, created_at: Time.zone.local(2012, 9, 1))
    subscribe(fee: previous_fee)
    late_cart = create(:cart, status: "paid", payment_completed: Time.zone.local(2026, 10, 31).end_of_day)
    subscribe(returning, cart: late_cart)
    future_cart = create(:cart, status: "paid", payment_completed: today.tomorrow.in_time_zone)
    subscribe(cart: future_cart)

    expect(counts[:membership]).to include("New Members" => [1, 0, 0, 0], "Renewed Members" => [0, 0, 1, 1])
  end

  it "counts lifetime members from their grant" do
    player = create(:player, status: "deceased")
    subscribe(player)
    create(:lifetime_subscription, player: player, created_at: Time.zone.local(2026, 10, 1))

    expect(counts[:membership]).to include("New Members" => [0, 1, 0, 0], "Lifetime Members" => [0, 0, 1, 1])
  end

  it "breaks down subscribers at each snapshot" do
    player = create(:player, dob: Date.new(2008, 11, 1), joined: Date.new(2025, 9, 1), gender: "F")
    subscribe(player)
    subscribe(create(:player_no_dob, gender: nil))
    create_list(:user, 2, player: player, created_at: today.in_time_zone, verified_at: nil)

    data = counts(columns: 2)
    expect(data[:accounts]).to eq("Has User" => [0, 1], "No User" => [2, 1])
    expect(data[:age]).to include("<18" => [1, 0], "18-24" => [0, 1], "Unknown" => [1, 1])
    expect(data[:gender]).to include("Female" => [1, 1], "Unknown" => [1, 1])
    expect(data.values.map { |groups| groups.values.sum(&:last) }).to eq [2, 2, 2, 2]
  end

  it "excludes unpaid, refunded, and duplicate records" do
    %w[unpaid refunded].each { |status| subscribe(status: status) }
    subscribe(create(:player, master: create(:player)))

    expect(counts(columns: 12)[:membership].values).to all(eq(Array.new(12, 0)))
  end
end
