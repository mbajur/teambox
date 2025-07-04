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

  factory :mislav, parent: :user do
    login { 'mislav' }
    email { 'mislav@fuckingawesome.com' }
    first_name { 'Mislav' }
    last_name { 'Marohnić' }
  end

  factory :confirmed_user, parent: :user do
  end

  factory :unconfirmed_user, parent: :user do
    splash_screen { true }
    confirmed_user { false }
  end
end
