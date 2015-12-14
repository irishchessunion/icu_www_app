module Admin
  class Statistic
    attr_accessor :name, :hour, :day, :week, :month, :year, :forever

    def initialize(args = {})
      args.each do |k, v|
        send("#{k}=", v)
      end
    end

    def self.all
      [logins, unique_logins, users]
    end

    def self.logins
      Statistic.new(name: 'Logins',
                    hour: logins_since(1.hour.ago),
                    day: logins_since(1.day.ago),
                    week: logins_since(1.week.ago),
                    month: logins_since(1.month.ago),
                    year: logins_since(1.year.ago),
                    forever: logins_since(Date.new(2010, 1, 1)))
    end

    def self.unique_logins
      Statistic.new(name: 'Unique Logins',
                    hour: unique_logins_since(1.hour.ago),
                    day: unique_logins_since(1.day.ago),
                    week: unique_logins_since(1.week.ago),
                    month: unique_logins_since(1.month.ago),
                    year: unique_logins_since(1.year.ago),
                    forever: unique_logins_since(Date.new(2010, 1, 1)))
    end

    def self.users
      Statistic.new(name: 'Viewers',
                    hour: users_since(1.hour.ago),
                    day: users_since(1.day.ago),
                    week: users_since(7.days.ago),
                    month: users_since(1.month.ago),
                    year: users_since(1.year.ago),
                    forever: users_since(Date.new(2010, 1, 1)))
    end

    # @param datetime [Datetime]
    def self.users_since(datetime)
      User.where('last_used_at > ?', datetime).count
    end

    # @param datetime [Datetime]
    def self.logins_since(datetime)
      Login.where('created_at > ?', datetime).count
    end

    # @param datetime [Datetime]
    def self.unique_logins_since(datetime)
      Login.where('max_created_at > ?', datetime).
          from(Login.select('max(created_at) as max_created_at').
          group(:user_id)).count
    end
  end
end