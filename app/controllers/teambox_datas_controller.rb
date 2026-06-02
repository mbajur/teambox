class TeamboxDatasController < ApplicationController
  skip_before_action :load_project
  before_action :load_teambox_data, only: [ :show, :download ]

  def index
    @exports = current_user.teambox_datas.where(type_id: TeamboxData::Attributes::TYPE_LOOKUP[:export]).order(created_at: :desc)
  end

  def new
    @teambox_data = TeamboxData.new(type_id: TeamboxData::Attributes::TYPE_LOOKUP[:export])
    @projects = Project.where(organization_id: current_user.admin_organization_ids)
  end

  def create
    @teambox_data = current_user.teambox_datas.build
    @teambox_data.type_id    = TeamboxData::Attributes::TYPE_LOOKUP[:export]
    @teambox_data.status     = TeamboxData::Attributes::EXPORT_STATUSES[:selecting]
    @teambox_data.projects   = Array(params.dig(:teambox_data, :projects)).compact.reject(&:blank?)

    if @teambox_data.save
      redirect_to teambox_data_path(@teambox_data)
    else
      @projects = Project.where(organization_id: current_user.admin_organization_ids)
      render :new
    end
  end

  def show
  end

  def download
    if @teambox_data.downloadable?(current_user) && @teambox_data.processed_data.exists?
      send_file @teambox_data.processed_data.path,
                filename: @teambox_data.processed_data_file_name,
                type: "application/json",
                disposition: "attachment"
    else
      redirect_to teambox_datas_path
    end
  end

  private

  def load_teambox_data
    @teambox_data = current_user.teambox_datas.find(params[:id])
  end
end
