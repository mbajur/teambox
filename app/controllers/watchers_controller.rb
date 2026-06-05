class WatchersController < ApplicationController
  def index
    @watchers = current_user.watchers.includes(:watchable)
  end

  def unwatch
    @watcher = current_user.watchers.find(params[:watch_id])
    @watcher.destroy
    redirect_to watch_list_path
  end
end
