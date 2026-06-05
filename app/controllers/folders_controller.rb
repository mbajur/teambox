class FoldersController < ApplicationController
  before_action :get_current_project_folder, only: [ :edit, :rename ]

  rescue_from CanCan::AccessDenied do |exception|
    handle_cancan_error(exception)
  end

  def edit
    authorize! :update, @folder

    respond_to do |f|
      f.js   { render layout: false }
      f.any(:html) { }
    end
  end

  def rename
    authorize! :update, @folder

    @folder.update(folder_params)
    respond_to do |f|
      f.js   { render layout: false }
      f.any(:html) do
        if @folder.valid?
          flash[:notice] = t("folders.rename.success")
        else
          flash[:error] =  [ t("folders.rename.error"), @folder.errors.full_messages.to_sentence ].join(". ")
        end
        redirect_to @parent_folder.nil? ? project_uploads_path(@current_project) : project_folder_path(@current_project, @parent_folder)
      end
    end
  end

  def create
    authorize! :create_folders, @current_project

    folder = Folder.new(folder_params.merge({ user_id: current_user.id, project_id: @current_project.id }))

    if folder.save
      redirect_to project_folder_path(@current_project, folder)
    else
      flash[:error] = [ t("folders.new.invalid_folder"), folder.errors.full_messages.to_sentence ].join(". ")
      redirect_to project_uploads_path(@current_project)
    end
  end

  def destroy
    @folder = @current_project.folders.find_by_id(params[:id])
    authorize! :destroy, @folder

    @current_folder = @folder.parent_folder

    @folder.destroy

    respond_to do |f|
      f.js   { render layout: false }
      f.any(:html) do
        flash[:success] = t("deleted.folder", name: @folder.name)
        redirect_to @parent_folder.nil? ? project_uploads_path(@current_project) : project_folder_path(@current_project, @parent_folder)
      end
    end
  end

  private

  def folder_params
    params.require(:folder).permit(:name, :user_id)
  end

  def get_current_project_folder
    @folder = @current_project.folders.find(params[:id])
  end
end
