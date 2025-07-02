FactoryBot.define do
  factory :project do
    name { generate(:name) }
    association :user
    association :organization
  end
end
