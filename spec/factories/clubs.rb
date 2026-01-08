FactoryBot.define do
  factory :club do
    name      { "Bangor Chess Club" }
    web       { nil }
    meet      { "Thursday night" }
    address   { nil }
    district  { nil }
    city      { "Bangor" }
    county    { "down" }
    eircode   { "D02 RR50" }
    lat       { rand(51.4..55.4) }
    long      { rand(-10.4..-5.5) }
    contact   { Faker::Name.name }
    email     { Faker::Internet.email }
    phone     { Faker::PhoneNumber.phone_number }
    active    { true }
  end
end
