FactoryBot.define do
  factory :page do
    name { 'Keys to the Castle' }

    user
    project
  end
end
