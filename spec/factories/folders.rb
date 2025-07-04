FactoryBot.define do
  factory :folder do
    name { generate(:folder_name) }
    association :project
    association :user
  end
end
