module TaskList::Scopes
  extend ActiveSupport::Concern

  included do
    default_scope { order("position ASC, created_at DESC") }
    scope :with_archived_tasks, -> { where("archived_tasks_count > 0") }
    scope :archived, -> { where(archived: true) }
    scope :unarchived, -> { where(archived: false) }
  end
end
