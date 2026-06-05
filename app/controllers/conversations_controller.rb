class ConversationsController < ApplicationController
  before_action :load_conversation, except: [ :index, :new, :create ]
  before_action :set_page_title

  rescue_from CanCan::AccessDenied do |exception|
    handle_cancan_error(exception)
  end

  def new
    authorize! :converse, @current_project
    @conversation = @current_project.conversations.new

    respond_to do |f|
      f.any(:html) { }
    end
  end

  def create
    authorize! :converse, @current_project
    @conversation = @current_project.conversations.new_by_user(current_user, conversation_params)
    @conversation.is_private = (conversation_params[:is_private]||false) if conversation_params

    if @conversation.save
      respond_to do |f|
        f.any(:html) {
          if request.xhr? or iframe?
            render partial: "activities/thread", locals: { thread: @conversation }
          else
            redirect_to current_conversation
          end
        }
      end
    else
      respond_to do |f|
        f.any(:html) {
          if request.xhr? or iframe?
            output_errors_json(@conversation)
          else
            # TODO: display inline instead of flash
            flash.now[:error] = @conversation.errors.to_a.first
            render action: :new
          end
        }
      end
    end
  end

  def index
    @conversations = @current_project.conversations.
      where([ "is_private = ? OR (is_private = ? AND watchers.user_id = ?)", false, true, current_user.id ]).
      joins("LEFT JOIN watchers ON (conversations.id = watchers.watchable_id AND watchers.watchable_type = 'Conversation') AND watchers.user_id = #{current_user.id}")

    respond_to do |f|
      f.any(:html)
      f.rss   { render layout: false }
    end
  end

  def show
    authorize! :show, @conversation
    @conversations = @current_project.conversations.not_simple.
      where("is_private = ? OR (is_private = ? AND watchers.user_id = ?)", false, true, current_user.id).
      joins("LEFT JOIN watchers ON (conversations.id = watchers.watchable_id AND watchers.watchable_type = 'Conversation') AND watchers.user_id = #{current_user.id}")


    respond_to do |f|
      f.any(:html)
    end
  end

  def update
    authorize! :update, @conversation
    success = @conversation.update_attributes(params[:conversation])

    respond_to do |f|
      f.js   { head :ok }
      f.any(:html) { redirect_to current_conversation }
    end
  end

  def destroy
    authorize! :destroy, @conversation
    @conversation.destroy

    respond_to do |f|
      f.any(:html) do
        flash[:success] = t("deleted.conversation", name: @conversation.to_s)
        redirect_to project_conversations_path(@current_project)
      end
      f.js { head :ok }
    end
  end

  def watch
    authorize! :watch, @conversation
    @conversation.add_watcher(current_user)

    respond_to do |f|
      f.js { render layout: false }
      f.any(:html) { redirect_to current_conversation }
    end
  end

  def unwatch
    @conversation.remove_watcher(current_user)

    respond_to do |f|
      f.js { render layout: false }
      f.any(:html) { redirect_to current_conversation }
    end
  end

  def convert_to_task
    authorize! :update, @conversation

    @conversation.attributes = conversation_params
    @conversation.updating_user = current_user
    @conversation.comments_attributes = { "0" => comment_params }

    success = @conversation.save
    if success
      @task = @conversation.convert_to_task!
      success = @task && @task.errors.empty?
    end

    if success
      if request.xhr? or iframe?
        if request.referer.ends_with?(project_conversation_path(@current_project, @conversation))
          render plain: project_task_path(@current_project, @task)
        else
          render partial: "activities/thread", locals: { thread: @task }
        end
      else
        # redirect_to current_conversation
        redirect_to project_task_path(@current_project, @task)
      end
    else
      respond_to do |f|
        f.turbo_stream
        f.html { render :edit }
      end
    end
  end

  private

  def conversation_params
    params.require(:conversation).permit(:name,
                                         :is_private,
                                         :simple,
                                         :due_on,
                                         :urgent,
                                         :status,
                                         :assigned_id,
                                         :task_list_id,
                                         watcher_ids: [],
                                         comments_attributes: [
                                           :is_private,
                                           :body,
                                           private_ids: [],
                                           uploads_attributes: [ :asset ]
                                         ])
  end

  def comment_params
    params[:comment]&.permit(:body) || {}
  end

  protected

    def load_conversation
      @conversation = @current_project.conversations.unscoped.find_with_deleted params[:id]
      redirect_to project_task_path(@current_project.id, @conversation.converted_to) if @conversation.deleted && @conversation.converted_to
      raise ActiveRecord::RecordNotFound if @conversation.deleted && @conversation.converted_to.nil?
    end

    def current_conversation
      [ @current_project, @conversation ]
    end
end
