class Admin::NewPlayersChart
  PERIODS = %w[month season year].freeze
  SERIES = {
    accounts: ["Has User", "No User"],
    age: ["<18", "18-24", "25-34", "35-44", "45-54", "55-64", "65-74", "75+", "Unknown"],
    gender: ["Male", "Female", "Unknown"]
  }.freeze

  def initialize(period: "month", today: Date.current)
    raise ArgumentError, "Invalid chart period" unless PERIODS.include?(period)

    @period = period
    @today = today
  end

  def data
    counts = SERIES.transform_values do |names|
      names.to_h { |name| [name, Array.new(starts.size, 0)] }
    end
    indices = starts.each_with_index.to_h { |date, index| [bucket_key(date), index] }

    grouped_counts.each do |bucket, accounts, age, gender, count|
      index = indices.fetch(bucket.to_s)
      { accounts: accounts, age: age, gender: gender }.each do |breakdown, name|
        counts.fetch(breakdown).fetch(name)[index] += count
      end
    end

    {
      categories: starts.map { |date| bucket_label(date) },
      series: counts.transform_values { |groups| groups.map { |name, values| { name: name, data: values } } }
    }
  end

  private

  def starts
    @starts ||= case @period
    when "month"
      Array.new(12) { |index| @today.beginning_of_month << (11 - index) }
    when "season"
      year = Season.new(@today).start.year
      (year - 7..year).map { |start_year| Date.new(start_year, 9, 1) }
    when "year"
      (@today.year - 7..@today.year).map { |year| Date.new(year, 1, 1) }
    end
  end

  def bucket_key(date)
    @period == "month" ? date.strftime("%Y-%m") : date.year.to_s
  end

  def bucket_label(date)
    case @period
    when "month" then date.strftime("%b %Y")
    when "season" then Season.new(date).to_s
    when "year" then date.year.to_s
    end
  end

  def bucket_sql
    case @period
    when "month" then "DATE_FORMAT(players.joined, '%Y-%m')"
    when "season"
      # Shift September to January to match the September 1 start in Season#start.
      "YEAR(DATE_SUB(players.joined, INTERVAL 8 MONTH))"
    when "year" then "YEAR(players.joined)"
    end
  end

  def grouped_counts
    accounts = "CASE WHEN users.id IS NULL THEN 'No User' ELSE 'Has User' END"
    gender = "CASE players.gender WHEN 'M' THEN 'Male' WHEN 'F' THEN 'Female' ELSE 'Unknown' END"
    age = <<~SQL.squish
      CASE
        WHEN players.dob IS NULL OR players.dob > players.joined THEN 'Unknown'
        WHEN TIMESTAMPDIFF(YEAR, players.dob, players.joined) < 18 THEN '<18'
        WHEN TIMESTAMPDIFF(YEAR, players.dob, players.joined) < 25 THEN '18-24'
        WHEN TIMESTAMPDIFF(YEAR, players.dob, players.joined) < 35 THEN '25-34'
        WHEN TIMESTAMPDIFF(YEAR, players.dob, players.joined) < 45 THEN '35-44'
        WHEN TIMESTAMPDIFF(YEAR, players.dob, players.joined) < 55 THEN '45-54'
        WHEN TIMESTAMPDIFF(YEAR, players.dob, players.joined) < 65 THEN '55-64'
        WHEN TIMESTAMPDIFF(YEAR, players.dob, players.joined) < 75 THEN '65-74'
        ELSE '75+'
      END
    SQL

    groups = [bucket_sql, accounts, age, gender].map { |sql| Arel.sql(sql) }
    Player.where(players: { player_id: nil, joined: starts.first..@today }).left_joins(:users).
      group(*groups).pluck(*groups, Arel.sql("COUNT(DISTINCT players.id)"))
  end
end
