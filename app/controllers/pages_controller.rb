class PagesController < ApplicationController
  before_action :load_page, only: [ :show, :edit, :update, :resort, :destroy, :watch, :unwatch ]
  before_action :set_page_title

  rescue_from CanCan::AccessDenied do |exception|
    handle_cancan_error(exception)
  end

  def index
    context = if @current_project
      @current_project.pages
    else
      Page.where(project_id: current_user.project_ids)
    end

    @pages = context.where([ "pages.is_private = ? OR (pages.is_private = ? AND watchers.user_id = ?)", false, true, current_user.id ]).
                     joins("LEFT JOIN watchers ON (pages.id = watchers.watchable_id AND watchers.watchable_type = 'Page') AND watchers.user_id = #{current_user.id}")

    respond_to do |f|
      f.any(:html)
      f.rss { render layout: false }
    end
  end

  def new
    authorize! :make_pages, @current_project
    @page = @current_project.new_page(current_user, params[:page])

    respond_to do |f|
      f.any(:html)
    end
  end

  def create
    authorize! :make_pages, @current_project
    @page = @current_project.new_page(current_user, page_params)
    respond_to do |f|
      if @page.save
        f.any(:html) { redirect_to project_page_path(@current_project, @page) }
      else
        f.any(:html) { render :new }
      end
    end
  end

  def show
    authorize! :show, @page
    @pages = @current_project.pages

    respond_to do |f|
      f.any(:html)
    end
  end

  def edit
    authorize! :update, @page
    respond_to do |f|
      f.html
    end
  end

  def update
    authorize! :update, @page
    @page.updating_user = current_user
    respond_to do |f|
      if @page.update(page_params)
        f.any(:html)  { redirect_to project_page_path(@current_project, @page) }
      else
        f.any(:html)  { render :edit }
      end
    end
  end

  def resort
    authorize! :reorder_objects, @current_project

    page_params = params.require(:page).permit(:position)
    @page.position = page_params[:position]
    @page.save!

    head :ok
  end

  def destroy
    if can? :destroy, @page
      @page.try(:destroy)

      respond_to do |f|
        flash[:success] = t("deleted.page", name: @page.to_s)
        f.any(:html)  { redirect_to project_pages_path(@current_project) }
      end
    else
      respond_to do |f|
        flash[:error] = t("common.not_allowed")
        f.any(:html) { redirect_to project_page_path(@current_project, @page) }
      end
    end
  end

  def watch
    authorize! :watch, @page
    @page.add_watcher(current_user)
    respond_to do |f|
      f.js { render layout: false }
    end
  end

  def unwatch
    @page.remove_watcher(current_user)
    respond_to do |f|
      f.js { render layout: false }
    end
  end

  private
    def page_params
      params.require(:page).permit(:name, :description, :content, :is_private, private_ids: [])
    end

    def load_page
      page_id = params[:id]
      @page = @current_project.pages.find_by_permalink(page_id) || @current_project.pages.find_by_id(page_id)

      unless @page
        flash[:error] = t("not_found.page", id: page_id)
        redirect_to project_path(@current_project)
      end
    end
end
