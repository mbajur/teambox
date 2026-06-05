FactoryBot.define do
  factory :reset_password do
    association :user

    after(:build) do |rp|
      rp.email ||= rp.user&.email
    end
  end
end
