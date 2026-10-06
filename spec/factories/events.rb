FactoryBot.define do
  factory :event do
    name       { "Ennis Congress" }
    location   { "West Country Hotels, Clare Road, Ennis" }
    start_date { Date.today.days_since(30) }
    end_date   { Date.today.days_since(33) }
    contact    { Faker::Name.name }
    email      { Faker::Internet.email(domain: "example.com") }  # events, clubs and players limit email to 50 characters
    phone      { Faker::PhoneNumber.phone_number }
    active     { true }
    category   { "irish" }
    user
  end
end
