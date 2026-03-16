FactoryBot.define do
  factory :arbiter do
    email                { Faker::Internet.email }
    phone                { Faker::PhoneNumber.phone_number }
    location             { "Dublin" }
    level                { "national" }
    date_of_qualification { Date.new(2024, 6, 1) }
    active               { true }
    available            { true }
    player
  end
end
