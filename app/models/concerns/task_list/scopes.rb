module TaskList::Scopes
  extend ActiveSupport::Concern

  included do
    default_scope { order(position: :asc, created_at: :desc) }

    scope :with_archived_tasks, -> { where("archived_tasks_count > 0") }
    scope :archived, -> { where(archived: true) }
    scope :unarchived, -> { where(archived: false) }
  end
end
