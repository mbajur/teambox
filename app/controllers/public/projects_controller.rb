class Public::ProjectsController < Public::PublicController
  def index
    @public_projects = Project.where(public: true).where.not(id: @projects.map(&:id)).order("updated_at DESC")
  end

  def show
    @activities = Activity.for_projects(@current_project).where(is_private: false)
    @threads = @activities.threads.all.includes(:project, :target)
    @last_activity = @threads.last
    @recent_conversations = Conversation.not_simple.where(is_private: false).recent(11).where(project_id: @project.id)
  end
end
