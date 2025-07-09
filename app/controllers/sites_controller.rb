# This controller handles custom organization pages and login for them
class SitesController < ApplicationController
  skip_before_action :require_authentication

  # skip_before_action :confirmed_user?
  skip_before_action :load_project
  skip_before_action :verify_authenticity_token, only: :create
  before_action :set_page_title, :load_organization

  layout "sites"

  def show
    # Cleanup OAuth login parameters if present
    session.delete :profile
    session.delete :app_link
  end

  def create
    terminate_session

    if user = User.authenticate_by(params.permit(:login, :password))
      start_new_session_for user
      flash[:error] = nil
      redirect_back fallback_location: root_url
    else
      note_failed_signin
      @login       = params[:login]
      @remember_me = true
      render :show
    end
  end

protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = t("sessions.new.login_failed", login: params[:login])
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end

  def load_organization
    @organization = Organization.find_by_permalink(params[:id])
    unless @organization
      render text: "That organization doesn't exist. But if it did, it'd surely be using Teambox!"
    end
  end
end
