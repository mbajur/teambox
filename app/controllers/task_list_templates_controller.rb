class TaskListTemplatesController < ApplicationController
  skip_before_action :load_project
  before_action :load_organization

  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = "You're not allowed to do that."
    redirect_to organization_memberships_path(@organization)
  end

  def index
    @task_list_templates = @organization.task_list_templates
  end

  def new
    @task_list_template = @organization.task_list_templates.new
    @task_list_template.tasks.build
  end

  def create
    task_list_template = @organization.task_list_templates.build(task_list_template_params)
    if task_list_template.save
      redirect_to(organization_task_list_templates_path(@organization), success: t(".success"))
    else
      head :error
    end
  end

  def edit
    @task_list_template = @organization.task_list_templates.find(params[:id])
    @task_list_template.tasks.build if @task_list_template.tasks.empty?
  end

  def update
    task_list_template = @organization.task_list_templates.find(params[:id])
    task_list_template.update(task_list_template_params)

    redirect_to(organization_task_list_templates_path(@organization), notice: t(".success"))
  end

  def destroy
    task_list_template = @organization.task_list_templates.find(params[:id])
    if task_list_template.destroy
      redirect_back(fallback_location: organization_task_list_templates_path(@organization), notice: t(".success"))
    else
      head :error
    end
  end

  def reorder
    task_list_template = @organization.task_list_templates.find(params[:id])
    task_list_template.update(position: params.require(:task_list_template).permit(:position)[:position])

    head :ok
  end

  protected

  def task_list_template_params
    params.require(:task_list_template).permit(:name, tasks_attributes: [ :id, :name, :description, :_destroy ])
  end

  def load_organization
    unless @organization = current_user.organizations.find_by_permalink(params[:organization_id])
      if organization = Organization.find_by_permalink(params[:organization_id])
        redirect_to external_view_organization_path(@organization)
      else
        flash[:error] = t("organizations.edit.invalid")
        redirect_to root_path
      end
    end
  end
end
