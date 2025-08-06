class SearchController < ApplicationController
  include Pagy::Backend

  before_action :permission_to_search

  def index
    @projects = current_user.projects.unarchived
    conditions = { project_id: Array(@projects).map(&:id),
                       status: Task::ACTIVE_STATUS_CODES }
    @tasks = Task.where(conditions)
                 .includes([ :task_list, :user, :project ])
                 .where([ "is_private = ? OR (is_private = ? AND watchers.user_id = ?)", false, true, current_user.id ])
                 .joins("LEFT JOIN watchers ON (tasks.id = watchers.watchable_id AND watchers.watchable_type = 'Task') AND watchers.user_id = #{current_user.id}")
                 .where("tasks.name LIKE ?", "%#{params[:q]}%")
    @pagy, @tasks = pagy(@tasks)
  end

  protected

    def permission_to_search
      unless current_user.can_search?
        flash[:notice] = "Search is disabled"
        redirect_to root_path
      end
    end
end
