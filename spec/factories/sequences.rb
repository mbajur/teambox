FactoryBot.define do
  sequence(:login) { |n| "gandhi_#{n}" }
  sequence(:email) { |n| "gandhi_#{n}@localhost.com" }
  sequence(:name) { |n| "Teambox ##{n}" }
  sequence(:folder_name) { |n| "the files #{n}" }
  sequence(:permalink) { |n| "teambox#{n}" }
end
