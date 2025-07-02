module TaskList::Associations
  extend ActiveSupport::Concern

  included do
    belongs_to :page, optional: true
    has_many :tasks, -> { order("position") }, dependent: :destroy
    has_many :comments, -> { order("created_at DESC") }, as: :target, dependent: :destroy

    has_one  :first_comment, -> { order("created_at ASC") }, class_name: "Comment", as: :target
    has_many :recent_comments, -> { order("created_at DESC").limit(2) }, class_name: "Comment", as: :target

    has_many :archived_tasks, -> { order("position").where("status >= ?", 3).includes(:project, :task_list, :assigned) }, class_name: "Task"
    has_many :unarchived_tasks, -> { order("position").where("status < ?", 3).includes(:project, :task_list, :assigned) }, class_name: "Task"
  end
end
