class ChartPeriod
  COUNTS = { "day" => 14, "week" => 12, "month" => 12, "season" => 8, "year" => 8 }.freeze

  def initialize(name, today: Date.current)
    @name = name
    @today = today
  end

  def starts
    @starts ||= Array.new(COUNTS.fetch(@name)) do |index|
      offset = COUNTS.fetch(@name) - index - 1
      case @name
      when "day" then @today - offset
      when "week" then @today.beginning_of_week(:monday) - offset.weeks
      when "month" then @today.beginning_of_month << offset
      when "season" then Season.new(@today).start.prev_year(offset)
      when "year" then @today.beginning_of_year.prev_year(offset)
      end
    end
  end

  def labels
    starts.map do |date|
      case @name
      when "day", "week" then date.strftime("%-d %b")
      when "month" then date.strftime("%b%y")
      when "season" then Season.new(date).to_s
      when "year" then date.year.to_s
      end
    end
  end

  def bucket_sql(column)
    case @name
    when "day" then "DATE(#{column})"
    when "week" then "DATE_SUB(DATE(#{column}), INTERVAL WEEKDAY(#{column}) DAY)"
    when "month" then "DATE_FORMAT(#{column}, '%Y-%m-01')"
    when "season" then "DATE_FORMAT(DATE_SUB(#{column}, INTERVAL 8 MONTH), '%Y-09-01')"
    when "year" then "DATE_FORMAT(#{column}, '%Y-01-01')"
    end
  end
end
