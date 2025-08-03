class CommentsController < ApplicationController
  before_action :load_comment, except: :create

  rescue_from CanCan::AccessDenied do |exception|
    handle_cancan_error(exception)
  end

  def create
    # pass the project so target.project lookup can be skipped
    authorize! :comment, target, @current_project

    comment = target.comments.create_by_user current_user, comment_params

    respond_to do |wants|
      wants.any(:html, :m)  {
        if request.xhr? or iframe?
          if comment.new_record?
            output_errors_json(comment)
          else
            response.headers["X-JSON"] = comment.target.to_json
            render partial: "comment", locals: { comment: comment }
          end
        else
          redirect_back_or_to root_path
        end
      }
    end
  end

  def edit
    authorize! :edit, @comment

    respond_to do |wants|
      wants.any(:html, :m) { render layout: false if request.xhr? }
    end
  end

  def update
    authorize! :update, @comment

    if @comment.update(comment_params)
      redirect_to ([ target.project, target ])
    else
      respond_to do |format|
        format.html { render :edit }
        format.turbo_stream
      end
    end
  end

  def destroy
    authorize! :destroy, @comment
    @comment.do_rollback = true
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to [ target.project, target ] }
      format.turbo_stream
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :is_private, private_ids: [], uploads_attributes: [ :asset ])
  end

  protected

  def target
    # can't use `memoize` because it freezes the object
    @target ||= if params[:conversation_id]
      @current_project.conversations.find params[:conversation_id]
    else
      @current_project.tasks.find params[:task_id]
    end
  end

  def load_comment
    @comment = target.comments.find params[:id]
  end
end
