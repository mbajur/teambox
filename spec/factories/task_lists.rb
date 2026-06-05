FactoryBot.define do
  factory :task_list_template_task do
    association :task_list_template
    name { 'A task' }
    description { nil }
  end

  factory :task_list_template do
    association :organization
    name { 'I will come up with a better name later' }

    after(:create) do |template|
      FactoryBot.create(:task_list_template_task, task_list_template: template, name: 'First task')
      FactoryBot.create(:task_list_template_task, task_list_template: template, name: 'Second task')
      FactoryBot.create(:task_list_template_task, task_list_template: template, name: 'Third task')
    end
  end

  factory :complete_task_list_template, parent: :task_list_template do
    after(:create) do |template|
      template.tasks.destroy_all
      FactoryBot.create(:task_list_template_task, task_list_template: template, name: 'First task', description: 'Bla bla bla')
      FactoryBot.create(:task_list_template_task, task_list_template: template, name: 'Second task', description: 'You motherfucker')
      FactoryBot.create(:task_list_template_task, task_list_template: template, name: 'Third task', description: 'Booh yah.')
    end
  end

  factory :task_list do
    name { 'Buy Groceries' }
    association :user
    association :project
  end
end
