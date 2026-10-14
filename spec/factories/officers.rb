FactoryBot.define do
  factory :officer do
    sequence(:name) { |n| "Officer #{n}" }
    rank         { 10 }
    executive    { true }
    player
  end
end
