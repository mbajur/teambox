class NotesController < ApplicationController
  before_action :load_page

  rescue_from CanCan::AccessDenied do |exception|
    handle_cancan_error(exception)
  end

  def create
    authorize! :update, @page

    @note = @page.build_note(note_params)
    @note.project    = @current_project
    @note.updated_by = current_user
    @note.slot_insert = {
      id: params[:position].try(:[], :slot).to_i,
      before: params[:position].try(:[], :before) == "1",
      footer: false
    }

    if @note.save
      redirect_to project_page_path(@current_project, @page)
    else
      redirect_to project_page_path(@current_project, @page), alert: @note.errors.full_messages.to_sentence
    end
  end

  def edit
    @note = @page.notes.find(params[:id])
    authorize! :update, @page
  end

  def update
    @note = @page.notes.find(params[:id])
    authorize! :update, @page

    @note.updated_by = current_user
    if @note.update(note_params)
      redirect_to project_page_path(@current_project, @page)
    else
      render :edit
    end
  end

  def destroy
    @note = @page.notes.find(params[:id])
    authorize! :update, @page

    @note.destroy
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

    def note_params
      params.require(:note).permit(:name, :body)
    end
end
