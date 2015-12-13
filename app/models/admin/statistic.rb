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
                    hour: Login.where('created_at > ?', 1.hour.ago).count,
                    day: Login.where('created_at > ?', 1.day.ago).count,
                    week: Login.where('created_at > ?', 1.week.ago).count,
                    month: Login.where('created_at > ?', 1.month.ago).count,
                    year: Login.where('created_at > ?', 1.year.ago).count,
                    forever: Login.count,
      )
    end

    def self.unique_logins
      Statistic.new(name: 'Unique Logins',
                    hour: Login.where('created_at > ?', 1.hour.ago).count,
                    day: Login.where('created_at > ?', 1.day.ago).count,
                    week: Login.where('created_at > ?', 1.week.ago).count,
                    month: Login.where('created_at > ?', 1.month.ago).count,
                    year: Login.where('created_at > ?', 1.year.ago).count,
                    forever: Login.count,
      )
    end

    def self.users
      Statistic.new(name: 'Users',
                    hour: User.where('last_used_at > ?', 1.hour.ago).count,
                    day: User.where('last_used_at > ?', 1.day.ago).count,
                    week: User.where('last_used_at > ?', 7.days.ago).count,
                    month: User.where('last_used_at > ?', 1.month.ago).count,
                    year: User.where('last_used_at > ?', 1.year.ago).count,
                    forever: User.where('last_used_at is not null').count,
      )
    end
  end
end