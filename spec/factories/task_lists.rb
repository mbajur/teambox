FactoryBot.define do
  factory :task_list_template do
    association :organization
    name { 'I will come up with a better name later' }
    tasks { [ [ 'First task' ], [ 'Second task' ], [ 'Third task' ] ] }
  end

  factory :complete_task_list_template, parent: :task_list_template do
    tasks { [ [ 'First task', 'Bla bla bla' ], [ 'Second task', 'You motherfucker' ], [ 'Third task', 'Booh yah.' ] ] }
  end

  factory :task_list do
    name { 'Buy Groceries' }
    association :user
    association :project
  end
end
