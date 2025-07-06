FactoryBot.define do
  factory :invitation do
    association :project
    user { project.user }
    email { generate(:email) }
  end
end
