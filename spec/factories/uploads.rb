FactoryBot.define do
  factory :upload do
    asset { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/dragon.jpg'), 'image/jpeg') }
    association :project
    association :user
  end
end
