module Task::Callbacks
  extend ActiveSupport::Concern

  included do
    before_create :init_task
    after_create :log_create, :update_user_stats
    after_save :set_watchers
    after_commit :update_activities_privacy, if: :is_private_previously_changed?, on: :update
    after_destroy :clear_targets
  end

  def init_task
    self.position ||= task_list.tasks.last ? task_list.tasks.last.position + 1 : 0
  end

  def log_create
    project.log_activity(self, "create")
  end

  def set_watchers
    add_watcher(user) if user
    add_watcher(assigned.user) if assigned
    true
  end

  def update_user_stats
    user.increment_stat "tasks" if user
  end

  def update_activities_privacy
    Activity.where(target: self)
      .or(Activity.where(comment_target: self))
      .update_all(is_private: self.is_private)
  end

  def clear_targets
    Activity.where(target_id: self.id, target_type: self.class.to_s).destroy_all
    Comment.where(target_id: self.id, target_type: self.class.to_s).destroy_all
  end
end
