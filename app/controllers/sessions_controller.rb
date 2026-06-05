# This controller handles the login/logout function of the site.
class SessionsController < ApplicationController
  skip_before_action :require_authentication, except: :destroy

  # skip_before_action :confirmed_user?
  # skip_before_action :load_project
  # skip_before_action :verify_authenticity_token, only: :create
  before_action :set_page_title
  before_action :community_version_check, except: [ :create, :backdoor ]

  def new
    @signups_enabled = signups_enabled?
    respond_to do |format|
      format.html { redirect_to root_path if authenticated? }
    end
  end

  def create
    if user = User.authenticate_by(params.permit(:login, :password))
      start_new_session_for user

      if session[:app_link_id]
        if app_link = AppLink.find_by_id(session[:app_link_id])
          app_link.user = user
          app_link.save
          session.delete :app_link_id
          flash[:success] = t(:'oauth.account_linked')
        end
      end

      respond_to do |format|
        format.html { redirect_back_or_to root_url }
      end
    else
      note_failed_signin
      @login       = params[:login]
      @remember_me = true
      render action: "new"
    end
    # @signups_enabled = signups_enabled?
    # logout_keeping_session!

    # user = User.authenticate(params[:login], params[:password])
    # if user
    #   # Protects against session fixation attacks, causes request forgery
    #   # protection if user resubmits an earlier form using back
    #   # button. Uncomment if you understand the tradeoffs.
    #   # reset_session
    #   self.current_user = user
    #   handle_remember_cookie! true
    #   flash[:error] = nil

    #   if session[:app_link_id]
    #     if app_link = AppLink.find_by_id(session[:app_link_id])
    #       app_link.user = user
    #       app_link.save
    #       session.delete :app_link_id
    #       flash[:success] = t(:'oauth.account_linked')
    #     end
    #   end

    #   respond_to do |format|
    #     format.html { redirect_back_or_to root_url }
    #   end
    # else
    #   note_failed_signin
    #   @login       = params[:login]
    #   @remember_me = true
    #   render action: "new"
    # end
  end

  def destroy
    terminate_session
    flash[:notice] = t("common.logged_out")
    redirect_to new_session_path
  end

  # for cucumber testing only
  def backdoor
    user = User.find_by_login(params[:username])
    return head :not_found unless user
    terminate_session
    start_new_session_for(user)
    redirect_back fallback_location: root_path
  end

protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = t("sessions.new.login_failed", login: params[:login])
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end

  def community_version_check
    return if authenticated?
    if Rails.configuration.teambox.community
      if User.count == 0
        respond_to do |f|
          f.html { render :configure_your_deployment }
        end
      elsif @organization = Organization.first
        respond_to do |f|
          f.html { render "sites/show", layout: "sites" }
        end
      else
        flash[:error] = "The configuration didn't finish. Please log in as #{User.first} and complete it by creating an organization."
        respond_to do |f|
          f.html { render :new }
        end
      end
    end
  end
end
