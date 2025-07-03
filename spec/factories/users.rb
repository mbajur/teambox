FactoryBot.define do
  factory :user do
    login { generate(:login) }
    email { generate(:email) }
    first_name { 'Andrew' }
    last_name { 'Wiggin' }
    password { 'dragons' }
    password_confirmation { 'dragons' }
    confirmed_user { true }
    splash_screen { false }
  end
end
