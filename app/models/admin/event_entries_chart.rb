class Admin::EventEntriesChart
  PERIODS = %w[day week month].freeze
  ENTRY_DATE_SQL = "COALESCE(carts.payment_completed, items.created_at)".freeze
  DEMOGRAPHICS = {
    gender: ChartDemographics::GENDERS,
    age: ChartDemographics::AGE_BANDS
  }.freeze

  def initialize(event, period: "day", today: Date.current)
    raise ArgumentError, "Invalid chart period" unless PERIODS.include?(period)

    @event = event
    @end_date = [today, event.start_date].min
    @period = ChartPeriod.new(period, today: @end_date)
  end

  def data
    sections = @event.section_names.index_with { empty_values }
    fees = @event.fee_entries.order(:name, :id).pluck(:id, :name).to_h do |id, name|
      [id, { name: name, data: empty_values }]
    end
    demographics = DEMOGRAPHICS.transform_values { |names| names.index_with { empty_values } }
    gross = empty_values
    indices = @period.starts.each_with_index.to_h

    grouped_totals.each do |bucket, section, fee_id, gender, age, count, amount|
      index = indices.fetch(Date.parse(bucket.to_s))
      section = section.presence || "No section"
      sections[section] ||= empty_values
      sections[section][index] += count
      fees.fetch(fee_id)[:data][index] += count
      { gender: gender, age: age }.each do |breakdown, name|
        demographics.fetch(breakdown).fetch(name)[index] += count
      end
      gross[index] += amount || 0
    end

    sections["No section"] = empty_values if sections.empty?

    {
      categories: @period.labels,
      series: {
        section: sections.map { |name, values| { name: name, data: values } },
        fee: fees.values.presence || [{ name: "Entries", data: empty_values }],
        **demographics.transform_values { |groups| groups.map { |name, values| { name: name, data: values } } },
        gross: [{ name: "Gross", data: gross.map(&:to_f) }]
      },
      currencies: { gross: "EUR" }
    }
  end

  private

  def empty_values
    Array.new(@period.starts.size, 0)
  end

  def grouped_totals
    bucket = Arel.sql(@period.bucket_sql(ENTRY_DATE_SQL))
    gender = Arel.sql(ChartDemographics::GENDER_SQL)
    age = Arel.sql(ChartDemographics.age_sql(Item.connection.quote(@event.start_date)))
    Item::Entry.paid.joins(:fee).left_joins(:cart, :player).where(fees: { event_id: @event.id }).
      where("#{ENTRY_DATE_SQL} >= ? AND #{ENTRY_DATE_SQL} < ?", @period.starts.first.in_time_zone, (@end_date + 1).in_time_zone).
      group(bucket, "items.section", "items.fee_id", gender, age).
      pluck(bucket, "items.section", "items.fee_id", gender, age, Arel.sql("COUNT(*)"), Arel.sql("SUM(items.cost)"))
  end
end
