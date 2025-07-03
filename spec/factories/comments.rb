FactoryBot.define do
  factory :comment do
    association :user
    association :project
    target { project }
    body { 'Just finished posting this comment' }
  end
end
