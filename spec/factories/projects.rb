FactoryBot.define do
  factory :project do
    name { generate(:name) }
    association :user
    association :organization
  end

  factory :ruby_rockstars, class: 'Project' do
    name { "Ruby Rockstars" }
    permalink { "ruby_rockstars" }
    user_id { (User.find_by(login: 'mislav') || FactoryBot.create(:mislav)).id }
    association :organization, name: "ACME"
  end

  factory :procial_network, class: 'Project' do
    name { "Procial Network" }
    permalink { "procial_network" }
    public { true }
    user_id { (User.find_by(login: 'mislav') || FactoryBot.create(:mislav)).id }
    association :organization, name: "ACME"
  end

  factory :archived_project, parent: :project do
    archived { true }
  end
end
