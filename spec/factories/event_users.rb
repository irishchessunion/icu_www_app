FactoryBot.define do
  factory :event_user do
    association :event
    association :user
    role { "full_access" }
  end
end
