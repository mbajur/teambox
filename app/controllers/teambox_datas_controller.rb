class TeamboxDatasController < ApplicationController
  skip_before_action :load_project
  before_action :load_teambox_data, only: [ :show, :download, :update ]

  def index
    @exports = current_user.teambox_datas.where(type_id: TeamboxData::Attributes::TYPE_LOOKUP[:export]).order(created_at: :desc)
    @imports = current_user.teambox_datas.where(type_id: TeamboxData::Attributes::TYPE_LOOKUP[:import]).order(created_at: :desc)
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

  def new_import
    @teambox_data = TeamboxData.new(type_id: TeamboxData::Attributes::TYPE_LOOKUP[:import])
    @organizations = current_user.admin_organizations
  end

  def create_import
    @teambox_data = current_user.teambox_datas.build
    @teambox_data.type_id = TeamboxData::Attributes::TYPE_LOOKUP[:import]
    @teambox_data.status  = TeamboxData::Attributes::IMPORT_STATUSES[:uploading]
    @teambox_data.service = params.dig(:teambox_data, :service) || "teambox"
    if params.dig(:teambox_data, :processed_data).present?
      @teambox_data.processed_data = params.dig(:teambox_data, :processed_data)
    end
    if @teambox_data.save
      redirect_to teambox_data_path(@teambox_data)
    else
      @organizations = current_user.admin_organizations
      render :new_import
    end
  end

  def show
    rescue_error = nil
    begin
      # trigger data loading to catch errors early
      @teambox_data.data if @teambox_data.type_name == :import
    rescue => e
      rescue_error = e
      Rails.logger.error "SHOW ERROR: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    end
    raise rescue_error if rescue_error
  end

  def update
    @teambox_data.user_map        = params.dig(:teambox_data, :user_map) || {}
    @teambox_data.organization_id = params.dig(:teambox_data, :organization_id).presence
    if @teambox_data.save
      redirect_to teambox_data_path(@teambox_data)
    else
      @organizations = current_user.admin_organizations
      render :show
    end
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
