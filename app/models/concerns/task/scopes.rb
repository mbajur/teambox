module Task::Scopes
  extend ActiveSupport::Concern

  included do
    default_scope -> { order("position ASC, created_at DESC") }
    scope :archived,   -> { where("status >= ?", 3).includes(:project, :task_list, :assigned) }
    scope :unarchived, -> { where("status <  ?", 3).includes(:project, :task_list, :assigned) }

    scope :active, -> { where(status: Task::ACTIVE_STATUS_CODES) }

    scope :assigned_to, lambda { |user|
      joins(assigned: :project).where(people: { user_id: user.id }).where(projects: { archived: false })
    }

    scope :urgent, -> { where(urgent: true).includes(:project, :task_list, :assigned) }
    scope :due_sooner_than_two_weeks, lambda {
      { conditions: [ "tasks.due_on < ?", 2.weeks.from_now ] }
    }

    scope :due_today, -> {
      where("due_on = ? AND tasks.completed_at is null", Date.today).includes(:task_list)
    }

    scope :upcoming, -> {
      where("due_on >= ? AND due_on <= ? AND tasks.completed_at is null", Date.today.monday, Date.today.monday + 2.weeks).includes(:task_list)
    }

    scope :upcoming_for_project, ->(project_id) {
      where("tasks.due_on >= ? AND tasks.due_on <= ? AND task_lists.project_id = ? AND tasks.completed_at is null",
        Date.today.monday, Date.today.monday + 2.weeks, project_id).includes(:task_list)
    }

    scope :from_pivotal_tracker, ->(story_id) {
      where("name LIKE ?", "%[PT#{story_id}]%")
    }
  end
end
