class HoursController < ApplicationController
  def index
    project_ids = current_user.project_ids

    @organizations = Organization.joins(:projects)
      .where(projects: { id: project_ids })
      .distinct
      .order(:name)

    @projects = current_user.projects.order(:name)

    scope = Comment.where(project_id: project_ids).where("hours > 0")

    if params[:org_filter].present?
      org_project_ids = Project.where(organization_id: params[:org_filter]).pluck(:id)
      scope = scope.where(project_id: org_project_ids & project_ids)
    end

    if params[:proj_filter].present?
      scope = scope.where(project_id: params[:proj_filter])
    end

    @comments = scope.preload(:project, :user, :target).order(created_at: :desc)
    @total_hours = @comments.sum(:hours)
  end
end
