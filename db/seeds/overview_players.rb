# Run with bin/rails runner db/seeds/overview_players.rb.
abort "Run this seed in development." unless Rails.env.development?

random = Random.new(20261029)
now = Time.current
today = now.to_date
season = Season.new(today)
first_names = {
  "M" => %w[Adam Brian Cian Daniel Eoin Finn Jack Liam Mark Sean],
  "F" => %w[Aisling Aoife Ciara Emma Fiona Grace Hannah Maeve Niamh Orla]
}
last_names = %w[Byrne Kelly Murphy Nolan Ryan Walsh Doyle Moore Quinn Reid]
age_ranges = [6..17, 18..24, 25..34, 35..44, 45..54, 55..64, 65..74, 75..88, nil]
recent_offsets = [5.minutes, 20.minutes, 1.hour, 3.hours, 8.hours, 1.day, 3.days, 1.week, 10.days, 14.days, 21.days, 28.days]

ActiveRecord::Base.transaction do
  100.times do |index|
    signup_at = if index < 12
      now - recent_offsets[index]
    else
      starts_on = if index < 60
        today.beginning_of_month << ((index - 12) % 12)
      else
        season.start.prev_year((index - 60) % 8)
      end
      ends_on = index < 60 ? starts_on.end_of_month : starts_on.next_year - 1
      ends_on = [ends_on, today].min
      joined_on = index.between?(60, 67) ? starts_on : starts_on + random.rand(0..(ends_on - starts_on).to_i)
      [joined_on.in_time_zone + random.rand(0...86_400).seconds, now].min
    end

    joined_on = signup_at.to_date
    age_range = age_ranges[index % age_ranges.size]
    dob = age_range && joined_on.prev_year(random.rand(age_range)) - random.rand(0..364)
    gender = index.even? ? "M" : "F"
    email = format("overview-player-%03d@example.test", index + 1)
    player = Player.find_or_initialize_by(email: email)
    player.assign_attributes(
      first_name: first_names.fetch(gender).sample(random: random),
      last_name: last_names.sample(random: random),
      gender: index % 20 == 19 ? nil : gender,
      dob: dob,
      joined: joined_on,
      fed: "IRL",
      status: "active",
      source: "import",
      note: "Sample player for the Overview page.",
      created_at: signup_at,
      updated_at: signup_at
    )
    player.save!

    next unless index % 5 < 2

    account_at = [signup_at + (index % 4).hours, now].min
    user = User.find_or_initialize_by(email: email)
    user.assign_attributes(
      player: player,
      password: "password1",
      status: User::OK,
      roles: nil,
      expires_on: season.end,
      verified_at: account_at,
      created_at: account_at,
      updated_at: account_at
    )
    user.save!
  end
end

puts "Seeded 100 overview sample players with 40 login accounts."
puts "Sample account password: password1"
