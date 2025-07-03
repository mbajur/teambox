FactoryBot.define do
  factory :person do
    association :project
    association :user
  end
end
