class StaticPagesController < ApplicationController
  layout "sessions"
  # skip_before_action :login_required

  def goodbye
    respond_to(:html)
  end
end
