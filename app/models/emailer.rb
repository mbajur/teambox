class Emailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  include Emailer::Incoming
  helper TasksHelper

  helper :application, :downloadable

  ANSWER_LINE = "-----------------------------==-----------------------------"

  class << self
    def emailer_defaults
      {
        content_type: "text/html",
        # :sent_on => Time.now,
        from: from_address
      }
    end

    def send_email(template, *args)
      send_with_language(template, :en, *args)
    end

    def send_with_language(template, language, *args)
      I18n.with_locale(language) do
        send(template, *args).deliver_now
      end
    end

    # can't use regular `receive` class method since it deals with Mail objects
    def receive_params(params)
      new.receive(params)
    end

    def from_user(reply_identifier, user)
      unless Rails.configuration.teambox.allow_incoming_email and reply_identifier
        reply_identifier = "no-reply"
      end

      from_address(reply_identifier, user.try(:name))
    end

    def from_address(recipient = "no-reply", name = "Teambox")
      domain = Rails.configuration.teambox.smtp_settings[:domain]
      address = "#{recipient}@#{domain}"

      if name.blank? or Rails.configuration.teambox.smtp_settings[:safe_from]
        address
      else
        %(#{name} <#{address}>)
      end
    end
  end

  default emailer_defaults

  def confirm_email(user_id)
    @user = User.find(user_id)
    @login_link = confirm_email_user_url(@user, token: @user.login_token)

    mail(
      to: @user.email,
      subject: I18n.t("emailer.confirm.subject")
    )
  end

  def reset_password(user_id)
    @user = User.find(user_id)
    mail(
      to: @user.email,
      subject: I18n.t("emailer.reset_password.subject")
    )
  end

  def forgot_password(reset_password_id)
    reset_password = ResetPassword.find(reset_password_id)
    @user = reset_password.user
    @url  = reset_password_url(reset_password.reset_code)
    mail(
      to: reset_password.user.email,
      subject: I18n.t("emailer.forgot_password.subject")
    )
  end

  def project_invitation(invitation_id)
    @invitation = Invitation.with_deleted.find(invitation_id)
    @referral   = @invitation.user
    @project    = @invitation.project
    mail(
      to: @invitation.email,
      from: self.class.from_user(nil, @invitation.user),
      reply_to: @invitation.user.email,
      subject: I18n.t("emailer.invitation.subject",
                            user: @invitation.user.name,
                            project: @invitation.project.name)
    )
  end

  def signup_invitation(invitation_id)
    @invitation = Invitation.find(invitation_id)
    @referral   = @invitation.user
    @project    = @invitation.project
    mail(
      to: @invitation.email,
      reply_to: @invitation.user.email,
      subject: I18n.t("emailer.invitation.subject",
                            user: @invitation.user.name,
                            project: @invitation.project.name)
    )
  end

  # Sent to the person who invited the user when an invitation is accepted
  def accepted_project_invitation(invited_user_id, invitation_id)
    @invitation     = Invitation.with_deleted.find(invitation_id)
    @referral       = @invitation.user
    @invited_user   = User.find(invited_user_id)
    @project        = @invitation.project
    mail(
      to: @referral.email,
      from: self.class.from_user(nil, @referral),
      subject: I18n.t("emailer.accepted_invitation.subject",
                            user: @invited_user.name,
                            project: @invitation.project.name)
    )
  end

  def notify_export(data_id)
    @data  = TeamboxData.find(data_id)
    @user  = @data.user
    @error = !@data.exported?
    mail(
      to: @data.user.email,
      subject: @error ? I18n.t("emailer.teamboxdata.export_failed") : I18n.t("emailer.teamboxdata.exported")
    )
  end

  def notify_import(data_id)
    @data  = TeamboxData.find(data_id)
    @user  = @data.user
    @error = !@data.imported?
    mail(
      to: @data.user.email,
      subject: @error ? I18n.t("emailer.teamboxdata.import_failed") : I18n.t("emailer.teamboxdata.imported")
    )
  end

  def notify_conversation(user_id, project_id, conversation_id)
    @project      = Project.find(project_id)
    @conversation = Conversation.find(conversation_id)
    @recipient    = User.find(user_id)
    @organization = @project.organization

    title         = @conversation.name.blank? ?
                    truncate(@conversation.comments.order("id ASC").first.body.strip) :
                    @conversation.name

    mail({
      to: @recipient.email,
      subject: "[#{@project.permalink}] #{title}"
    }.merge(
      from_reply_to "#{@project.permalink}+conversation+#{@conversation.id}", @conversation.comments.first.user
    ))
  end

  def notify_task(user_id, project_id, task_id)
    @project      = Project.find(project_id)
    @task         = Task.find(task_id)
    @task_list    = @task.task_list
    @recipient    = User.find(user_id)
    @organization = @task.project.organization
    mail({
      to: @recipient.email,
      subject: "[#{@project.permalink}] #{@task.name}#{task_description(@task)}"
    }.merge(
      from_reply_to "#{@project.permalink}+task+#{@task.id}", @task.comments.first.user
    ))
  end

  def notify_activity(user_id, project_id, activity_id)
    @project      = Project.find(project_id)
    @activity     = Activity.find(activity_id)
    @recipient    = User.find(user_id)
    @organization = @project.organization
    mail({
      to: @recipient.email,
      subject: "[#{@project.permalink}] " +
        I18n.t("emailer.notify.activity.#{@activity.action_type.downcase}.subject", name: @activity.user.name)
    })
  end

  def project_membership_notification(invitation_id)
    @invitation = Invitation.find_with_deleted(invitation_id)
    @project    = @invitation.project
    @recipient  = @invitation.invited_user
    mail({
      to: @invitation.invited_user.email,
      subject: I18n.t("emailer.project_membership_notification.subject",
                               user: @invitation.user.name,
                               project: @invitation.project.name)
    }.merge(
      from_reply_to "#{@invitation.project.permalink}", @invitation.user
    ))
  end

  def daily_task_reminder(user_id)
    @user  = User.find(user_id)
    @tasks = @user.tasks_for_daily_reminder_email
    mail(
      to: @user.email,
      subject: I18n.t("users.daily_task_reminder_email.daily_task_reminder")
    )
  end

  def bounce_message(exception_mail, pretty_exception)
    info_url = "http://help.teambox.com/knowledgebase/articles/10243-using-teambox-via-email"

    mail(
      to: exception_mail,
      subject: I18n.t("emailer.bounce.subject"),
      body: I18n.t("emailer.bounce.#{pretty_exception}") + "\n\n---\n" +
                     I18n.t("emailer.bounce.not_delivered", link: info_url)
    )
  end

  def simple_message(user_id, subject, message)
    @user = User.find(user_id)
    @message = message
    mail({
      to: @user.email,
      subject: subject
    })
  end

  def project_digest(user_id, person_id, project_id, target_types_and_ids, comment_ids)
    @recipient     = User.find(user_id)
    @person        = Person.find(person_id)
    @project       = Project.find(project_id)
    @targets = target_types_and_ids.map do |target|
      target = target.with_indifferent_access
      target[:target_type].constantize.find_by_id target[:target_id]
    end.compact.uniq
    @comments      = Comment.where(id: comment_ids)

    mail({
      to: @recipient.email,
      subject: I18n.t("emailer.digest.title.#{@person.digest_type}", project: @project.name)
    })
  end

  def public_download(downloadable_id, recipient, downloadable_type)
    @downloadable_type = downloadable_type
    @downloadable = downloadable_type.classify.constantize.find(downloadable_id)
    @user   = @downloadable.user
    mail(
      to: recipient,
      from: self.class.from_user(nil, @user),
      subject: I18n.t("emailer.public_download.#{downloadable_type}.subject", user: @user.name)
    )
  end

  private

    def from_reply_to(reply_identifier, user)
      reply_address = self.class.from_user(reply_identifier, nil)
      { from: self.class.from_user(reply_identifier, user) }.merge(
        reply_address.starts_with?("no-reply") ? {} : { reply_to: reply_address }
      )
    end

    def task_description(task)
      desc = task.comments.first.try(:body)
      task_description = truncate(desc ? desc : "", length: 50)
      task_description.blank? ? "" : " - #{task_description}"
    end
end
