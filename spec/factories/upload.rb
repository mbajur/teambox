FactoryBot.define do
  factory :upload do
    asset_file_name { 'pic.png' }
    asset_file_size { 42 }
    asset_content_type { 'image/png' }
    association :project
    association :user
  end
end
