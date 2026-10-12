FactoryBot.define do
  factory :api_key do
    sequence(:name) { |n| "Chess Site #{n}" }
    permissions     { "events" }
    active          { true }
  end
end
