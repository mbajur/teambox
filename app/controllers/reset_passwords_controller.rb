class ResetPasswordsController < ApplicationController
  layout "sessions"
  skip_before_action :require_authentication
  skip_before_action :load_project

  def new
    @reset_password = ResetPassword.new
  end

  def create
    @reset_password = ResetPassword.new(reset_password_params)
    @reset_password.user = User.find_by(email: @reset_password.email)

    if @reset_password.save
      Emailer.forgot_password(@reset_password.id).deliver_now
      flash[:notice] = t("reset_passwords.sent.login_link_sent", email: @reset_password.email)
      redirect_to sent_password_path
    else
      if @reset_password.errors[:user].present?
        flash.now[:error] = t("reset_passwords.create.not_found_html",
          email: @reset_password.email,
          support: Rails.configuration.teambox.support).html_safe
      else
        flash.now[:error] = @reset_password.errors.full_messages.join(", ")
      end
      render :new
    end
  end

  def sent
  end

  def reset
    @reset_password = ResetPassword.find_by(reset_code: params[:reset_code])
    user = @reset_password && User.with_deleted.find_by(id: @reset_password.user_id)
    unless @reset_password && user && !user.deleted? && @reset_password.expiration_date > Time.now
      flash[:error] = t("reset_passwords.create.invalid_html",
        support: Rails.configuration.teambox.support).html_safe
      redirect_to new_session_path and return
    end
  end

  def update
    @reset_password = ResetPassword.find(params[:id])
    user = User.with_deleted.find_by(id: @reset_password.user_id)

    unless @reset_password && user && !user.deleted? && @reset_password.expiration_date > Time.now
      flash[:error] = t("reset_passwords.create.invalid_html",
        support: Rails.configuration.teambox.support).html_safe
      redirect_to new_session_path and return
    end

    user.activate = true
    user.password = params[:user][:password]
    user.password_confirmation = params[:user][:password_confirmation]

    if user.password.blank? || !user.save
      flash.now[:error] = t("reset_passwords.create.password_not_updated")
      render :reset and return
    end

    @reset_password.destroy
    user.update_column(:confirmed_user, true) unless user.confirmed_user?

    start_new_session_for user
    flash[:success] = t("reset_passwords.create.password_updated")
    redirect_to projects_path
  end

  def update_after_forgetting
    redirect_to new_session_path
  end

  private

  def reset_password_params
    params.require(:reset_password).permit(:email)
  end
end
