module Task::Callbacks
  extend ActiveSupport::Concern

  included do
    before_create :init_task
    after_create :log_create, :update_user_stats
    after_save :set_watchers
    after_destroy :clear_targets
  end

  def init_task
    self.position ||= task_list.tasks.last ? task_list.tasks.last.position + 1 : 0
  end

  def log_create
    project.log_activity(self, "create")
  end

  def set_watchers
    add_watcher(assigned.user) if assigned
    true
  end

  def update_user_stats
    # user.increment_stat "tasks" if user
  end

  def clear_targets
    Activity.where(target_id: self.id, target_type: self.class.to_s).destroy_all
    Comment.where(target_id: self.id, target_type: self.class.to_s).destroy_all
  end
end
