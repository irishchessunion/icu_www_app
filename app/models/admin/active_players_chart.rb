class Admin::ActivePlayersChart
  PERIODS = %w[month season].freeze
  SERIES = {
    membership: ["Renewed Members", "New Members", "Lifetime Members"],
    accounts: ["Has User", "No User"],
    age: ChartDemographics::AGE_BANDS,
    gender: ChartDemographics::GENDERS
  }.freeze
  LIFETIME_SQL = "items.description LIKE 'Lifetime%'".freeze

  def initialize(period: "month", today: Date.current)
    raise ArgumentError, "Invalid chart period" unless PERIODS.include?(period)

    @period = ChartPeriod.new(period, today: today)
    @snapshots = @period.starts.drop(1).map(&:yesterday) << today
  end

  def data
    counts = SERIES.transform_values do |names|
      names.index_with { Array.new(@snapshots.size, 0) }
    end
    indices = @snapshots.each_with_index.to_h

    grouped_counts.each do |snapshot, membership, accounts, age, gender, count|
      index = indices.fetch(snapshot.to_date)
      { membership: membership, accounts: accounts, age: age, gender: gender }.each do |breakdown, name|
        counts.fetch(breakdown).fetch(name)[index] += count
      end
    end

    {
      categories: @period.labels,
      series: counts.transform_values { |groups| groups.map { |name, values| { name: name, data: values } } }
    }
  end

  private

  def grouped_counts
    membership = <<~SQL.squish
      CASE
        WHEN memberships.lifetime = 1 THEN 'Lifetime Members'
        WHEN EXISTS (#{prior_subscriptions.to_sql}) THEN 'Renewed Members'
        ELSE 'New Members'
      END
    SQL
    accounts = <<~SQL.squish
      CASE WHEN EXISTS (
        SELECT 1 FROM users WHERE users.player_id = players.id AND users.created_at < memberships.cutoff_at
      ) THEN 'Has User' ELSE 'No User' END
    SQL
    breakdowns = {
      membership_type: membership,
      login_account: accounts,
      age_band: ChartDemographics.age_sql("memberships.snapshot_on"),
      gender_group: ChartDemographics::GENDER_SQL
    }
    columns = breakdowns.map { |name, sql| Arel.sql("#{sql} AS #{name}") }

    Player.non_duplicates.joins("INNER JOIN (#{active_memberships.to_sql}) memberships ON memberships.member_id = players.id").
      group("memberships.snapshot_on", *breakdowns.keys.map(&:to_s)).
      pluck("memberships.snapshot_on", *columns, Arel.sql("COUNT(*)"))
  end

  def active_memberships
    # Collapse overlapping subscriptions to one row per player and snapshot.
    Item::Subscription.paid_before(Arel.sql("snapshots.cutoff_at")).
      joins("CROSS JOIN (#{snapshot_table}) snapshots").
      where("(items.start_date <= snapshots.snapshot_on AND items.end_date >= snapshots.snapshot_on) OR #{LIFETIME_SQL}").
      group("snapshots.snapshot_on", "snapshots.cutoff_at", "items.player_id").
      select("snapshots.snapshot_on", "snapshots.cutoff_at", "items.player_id AS member_id",
             "MIN(items.start_date) AS season_start", "MAX(#{LIFETIME_SQL}) AS lifetime")
  end

  def prior_subscriptions
    Item::Subscription.paid_before(Arel.sql("memberships.cutoff_at")).
      where("items.player_id = memberships.member_id AND items.end_date < memberships.season_start").select("1")
  end

  def snapshot_table
    connection = Item.connection
    @snapshots.map do |date|
      <<~SQL.squish
        SELECT CAST(#{connection.quote(date)} AS DATE) AS snapshot_on,
               CAST(#{connection.quote((date + 1).in_time_zone)} AS DATETIME) AS cutoff_at
      SQL
    end.join(" UNION ALL ")
  end
end
