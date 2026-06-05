class TasksController < ApplicationController
  around_action :set_time_zone, only: [ :show ]
  before_action :load_task, except: [ :new, :create ]
  before_action :load_task_list, only: [ :new, :create ]
  before_action :set_page_title

  rescue_from CanCan::AccessDenied do |exception|
    handle_cancan_error(exception)
  end

  def show
    authorize! :show, @task
    respond_to do |f|
      f.any(:html)
      f.js {
        @show_part = params[:part]
        render template: "tasks/reload"
      }
    end
  end

  def new
    authorize! :make_tasks, @current_project
    @task = @task_list.tasks.new

    respond_to do |f|
      f.any(:html)
    end
  end

  # @todo support turbo streams and refreshing task list on task creation
  def create
    authorize! :make_tasks, @current_project
    @task = @task_list.tasks.build_by_user(current_user, task_params)
    @task.is_private = (task_params[:is_private]||false) if task_params
    @task.save

    if @task.new_record?
      render :new, status: :unprocessable_entity
    else
      if @task.redirect_mode == "back"
        respond_to do |f|
          f.turbo_stream
          f.html { redirect_back fallback_location: [ @current_project, @task ] }
        end
      else
        redirect_to_task
      end
    end
  end

  def edit
    authorize! :update, @task
    respond_to do |f|
      f.any(:html)
      f.js { render layout: false }
    end
  end

  def update
    if can? :update, @task
      @task.updating_user = current_user
      success = @task.update!(task_params)
    elsif can? :comment, @task
      @task.updating_user = current_user
      success = @task.update!(comments_attributes: params["task"]["comments_attributes"])
    else
      authorize! :comment, @task
    end

    respond_to do |f|
      f.any(:html) {
        if request.xhr? or iframe?
          if success and @task.comment_created?
            comment = @task.comments(true).first
            response.headers["X-JSON"] = @task.to_json(include: :assigned)

            render partial: "comments/comment",
              locals: { comment: comment }
          else
            render nothing: true, status: :unprocessable_entity
          end
        else
          if success
            redirect_to_task
          else
            render :edit, status: :unprocessable_entity
          end
        end
      }
      f.js {
        if params[:task][:name]
          head :ok
        end
      }
    end
  end

  def destroy
    authorize! :destroy, @task
    @task.destroy

    respond_to do |f|
      f.any(:html) {
        flash[:success] = t("deleted.task", name: @task.to_s)
        redirect_to [ @current_project, @task_list ]
      }
      f.js { render layout: false }
    end
  end

  def reorder
    authorize! :reorder_objects, @current_project

    task_params = params.require(:task).permit(:task_list_id, :position, position: [ :before, :after ])

    @task.position = task_params[:position].try(:to_h)
    @task.task_list = @current_project.task_lists.find(task_params[:task_list_id])
    @task.save!

    head :ok
  end

  def watch
    authorize! :watch, @task
    @task.add_watcher(current_user)
    respond_to do |f|
      f.turbo_stream
    end
  end

  def unwatch
    @task.remove_watcher(current_user)
    respond_to do |f|
      f.turbo_stream
    end
  end

  private

    def task_params
      params.require(:task).permit(:name,
                                   :description,
                                   :is_private,
                                   :status,
                                   :assigned_id,
                                   :due_on,
                                   :urgent,
                                   :redirect_mode,
                                   comments_attributes: [ :body, :is_private, private_ids: [] ])
    end

    def load_task_list
      @task_list = if params[:id]
        @current_project.tasks.find(params[:id]).task_list
      elsif params[:task_list_id]
        @current_project.task_lists.find params[:task_list_id]
      end
    end

    def load_task
      @task = @current_project.tasks.find params[:id]
      @task_list = @task.task_list
    end

    def redirect_to_task
      redirect_to [ @current_project, @task ]
    end
end
