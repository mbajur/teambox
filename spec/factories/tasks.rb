FactoryBot.define do
  factory :task do
    name { 'Buy milk' }
    association :user
    association :project
    association :task_list

    factory :archived_task do
      archived { true }
    end

    factory :held_task do
      status { Task::STATUSES[:hold] }
    end

    factory :resolved_task do
      status { Task::STATUSES[:resolved] }
    end

    factory :rejected_task do
      status { Task::STATUSES[:rejected] }
    end
  end
end
