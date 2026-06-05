class DividersController < ApplicationController
  before_action :load_page

  rescue_from CanCan::AccessDenied do |exception|
    handle_cancan_error(exception)
  end

  def create
    authorize! :update, @page

    @divider = @page.build_divider(divider_params)
    @divider.project = @current_project
    @divider.slot_insert = {
      id: params[:position].try(:[], :slot).to_i,
      before: params[:position].try(:[], :before) == "1",
      footer: false
    }

    if @divider.save
      redirect_to project_page_path(@current_project, @page)
    else
      redirect_to project_page_path(@current_project, @page), alert: @divider.errors.full_messages.to_sentence
    end
  end

  def edit
    @divider = @page.dividers.find(params[:id])
    authorize! :update, @page
  end

  def update
    @divider = @page.dividers.find(params[:id])
    authorize! :update, @page

    if @divider.update(divider_params)
      redirect_to project_page_path(@current_project, @page)
    else
      render :edit
    end
  end

  def destroy
    @divider = @page.dividers.find(params[:id])
    authorize! :update, @page

    @divider.destroy
    redirect_to project_page_path(@current_project, @page)
  end

  private

    def load_page
      page_id = params[:page_id]
      @page = @current_project.pages.find_by_permalink(page_id) || @current_project.pages.find_by_id(page_id)

      unless @page
        flash[:error] = t("not_found.page", id: page_id)
        redirect_to project_path(@current_project)
      end
    end

    def divider_params
      params.require(:divider).permit(:name)
    end
end
