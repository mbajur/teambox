require "hashie"

class AuthController < ApplicationController
  skip_before_action :require_authentication

  def mock
    provider = params[:provider]
    mock_data = OmniAuth.config.mock_auth[provider.to_sym]

    if mock_data
      session[:omniauth_auth] = mock_data
      redirect_to "/auth/#{provider}/callback"
    else
      redirect_to auth_failure_url(message: "mock_not_configured")
    end
  end

  def callback
    provider = params[:provider]
    auth_data = session.delete(:omniauth_auth)

    unless auth_data.present?
      redirect_on_failure
      return
    end

    auth_hash = ::Hashie::Mash.new(auth_data)
    app_link = AppLink.find_or_create_or_update_from_authentification(provider, auth_hash, current_user)

    if current_user
      if current_user.id == app_link.user_id
        flash[:success] = t(:'oauth.account_linked')
      else
        flash[:error] = t(:'oauth.already_taken_by_other_account')
      end
      redirect_to account_linked_accounts_url
    elsif app_link.user
      start_new_session_for app_link.user
      flash[:success] = t(:'oauth.logged_in')
      redirect_to projects_url
    elsif !signups_enabled?
      flash[:error] = t(:'users.new.no_public_signup')
      redirect_to login_url
    else
      session[:app_link_id] = app_link.id
      redirect_to signup_url
    end
  end

  def failure
    redirect_on_failure params[:message].to_s.humanize
  end

  private

  def redirect_on_failure(message = nil)
    message ||= "communication error"
    flash[:error] = t("oauth.authentication_failure", message: message)
    if current_user
      redirect_to account_linked_accounts_url
    else
      redirect_to login_url
    end
  end
end
