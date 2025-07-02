module TaskList::Initializers
  extend ActiveSupport::Concern

  def new_task(user, task = nil)
    self.tasks.new(task) do |task|
      task.project_id = self.project_id
      task.user_id = user.id
    end
  end
end
