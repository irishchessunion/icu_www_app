require 'rails_helper'

describe Admin::NewPlayersChart do
  let(:today) { Date.new(2026, 10, 29) }

  def chart(period = "month", date = today)
    described_class.new(period: period, today: date).data
  end

  def values(data, breakdown, name)
    data.fetch(:series).fetch(breakdown).find { |series| series[:name] == name }.fetch(:data)
  end

  it "includes twelve months, fills empty months, and counts by joining date through today" do
    create(:player, joined: Date.new(2025, 11, 1))
    create(:player, joined: Date.new(2026, 10, 1), created_at: Date.new(2025, 1, 1))
    create(:player, joined: today)
    create(:player, joined: Date.new(2025, 10, 31))
    create(:player, joined: today).update_column(:joined, today + 1)

    data = chart
    expect(data[:categories]).to eq ["Nov 2025", "Dec 2025", "Jan 2026", "Feb 2026", "Mar 2026", "Apr 2026", "May 2026", "Jun 2026", "Jul 2026", "Aug 2026", "Sep 2026", "Oct 2026"]
    expect(values(data, :accounts, "No User")).to eq [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2]
  end

  it "groups eight seasons with a September boundary" do
    create(:player, joined: Date.new(2019, 9, 1))
    create(:player, joined: Date.new(2019, 8, 31))
    create(:player, joined: Date.new(2026, 8, 31))
    create(:player, joined: Date.new(2026, 9, 1))

    data = chart("season")
    expect(data[:categories]).to eq %w[2019-20 2020-21 2021-22 2022-23 2023-24 2024-25 2025-26 2026-27]
    expect(values(data, :accounts, "No User")).to eq [1, 0, 0, 0, 0, 0, 1, 1]

    data = chart("season", Date.new(2026, 8, 31))
    expect(data[:categories].last).to eq "2025-26"
    expect(values(data, :accounts, "No User").last).to eq 1
  end

  it "groups eight calendar years including the current year to date" do
    create(:player, joined: Date.new(2019, 1, 1))
    create(:player, joined: Date.new(2018, 12, 31))
    create(:player, joined: Date.new(2025, 12, 31))
    create(:player, joined: Date.new(2026, 1, 1))
    create(:player, joined: today)

    data = chart("year")
    expect(data[:categories]).to eq %w[2019 2020 2021 2022 2023 2024 2025 2026]
    expect(values(data, :accounts, "No User")).to eq [1, 0, 0, 0, 0, 0, 1, 2]
  end

  it "counts each player once even when they have multiple login accounts" do
    player = create(:player, joined: today)
    create(:user, player: player)
    create(:user, player: player, verified_at: nil)
    create(:player, joined: today)

    data = chart
    expect(values(data, :accounts, "Has User").last).to eq 1
    expect(values(data, :accounts, "No User").last).to eq 1
    expect(values(data, :gender, "Male").last).to eq 2
  end

  it "includes every status but excludes duplicates and players without a joining date" do
    players = Player::STATUSES.map { |status| create(:player, joined: today, status: status) }
    create(:player, joined: today, player_id: players.first.id)
    create(:player, source: "import", joined: nil)

    expect(values(chart, :accounts, "No User").last).to eq 4
  end

  it "uses exact ages when joining, including birthdays and all age band boundaries" do
    joined = Date.new(2020, 1, 15)
    create(:player, joined: joined, dob: Date.new(2002, 1, 16))
    [18, 25, 35, 45, 55, 65, 75].each do |age|
      create(:player, joined: joined, dob: joined.prev_year(age))
      create(:player, joined: joined, dob: joined.prev_year(age) + 1)
    end

    data = chart("year")
    expected = [2, 2, 2, 2, 2, 2, 2, 1, 0]
    expect(data[:series][:age].map { |series| series[:data][1] }).to eq expected
  end

  it "keeps unknown demographics in the totals" do
    create(:player, joined: today, gender: "F")
    create(:player, joined: today, gender: "M")
    create(:player, joined: today, source: "import", dob: nil, gender: nil)

    data = chart
    expect(values(data, :gender, "Male").last).to eq 1
    expect(values(data, :gender, "Female").last).to eq 1
    expect(values(data, :gender, "Unknown").last).to eq 1
    expect(values(data, :age, "Unknown").last).to eq 1
    expect(data[:series].values.map { |series| series.sum { |group| group[:data].sum } }).to eq [3, 3, 3]
  end

  it "fetches all breakdowns in one grouped query without instantiating player or user records" do
    create(:user, player: create(:player, joined: today))
    queries = []
    instantiated = []
    query_listener = ->(*args) { queries << args.last[:sql] unless args.last[:name] == "SCHEMA" }
    record_listener = ->(*args) { instantiated << args.last[:class_name] }

    ActiveSupport::Notifications.subscribed(query_listener, "sql.active_record") do
      ActiveSupport::Notifications.subscribed(record_listener, "instantiation.active_record") { chart }
    end

    expect(queries.size).to eq 1
    expect(instantiated).to be_empty
  end
end
