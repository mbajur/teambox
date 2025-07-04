FactoryBot.define do
  factory :conversation do
    name { 'The Master Plan' }
    body { 'Shorter than a New York minute' }
    simple { false }

    user
    project

    factory :simple_conversation do
      name { nil }
      simple { true }
    end
  end
end
