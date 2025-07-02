FactoryBot.define do
  factory :organization do
    name { generate(:name) }
    permalink { generate(:permalink) }
  end
end
