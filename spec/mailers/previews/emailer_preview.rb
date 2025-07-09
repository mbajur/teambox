class EmailerPreview < ActionMailer::Preview
  def notify_task
    task = Task.last
    Emailer.notify_task(task.user.id, task.project.id, task.id)
  end

  def notify_conversation
    conversation = Conversation.last
    Emailer.notify_conversation(conversation.user.id, conversation.project.id, conversation.id)
  end

  def notify_activity_on_page
    activity = Activity.where(target_type: "Page").first!
    Emailer.notify_activity(activity.user_id, activity.project_id, activity.id)
  end

  def notify_activity_on_note
    activity = Activity.where(target_type: "Note").first!
    Emailer.notify_activity(activity.user_id, activity.project_id, activity.id)
  end

  def project_digest
    project_id  = Project.last.id
    person_id   = Project.last.people.first.id
    user        = Project.last.users.first
    user_id     = user.id

    target_types_and_ids = []
    comment_ids = []

    user.notifications.each do |notification|
      target_types_and_ids << { target_type: notification.target_type, target_id: notification.target_id }
      comment_ids << notification.comment_id unless notification.comment_id.nil?
    end

    target_types_and_ids.uniq!
    comment_ids = comment_ids[(comment_ids.size/3) .. (comment_ids.size)].uniq

    Emailer.project_digest(user_id, person_id, project_id, target_types_and_ids, comment_ids)
  end

  def daily_task_reminder
    user = User.find_by_login "frank"
    Emailer.daily_task_reminder(user.id)
  end

  def signup_invitation
    other_invitation = Invitation.new do |i|
      i.invited_user = User.create!(login: "pepito", password: "papapa", password_confirmation: "papapa", first_name: "Pepito", last_name: "Delospalotes", email: "pepito@teambox.com") rescue User.find_by_login("pepito")
      i.token = SecureRandom.hex(20)
      i.user = User.first
      i.project = Project.first
    end
    other_invitation.save!
    invitation = Invitation.new do |i|
      i.email = "test@teambox.com"
      i.token = SecureRandom.hex(20)
      i.user = User.first
      i.project = Project.first
    end
    invitation.save!

    Emailer.signup_invitation(invitation.id)
  end

  def reset_password
    user = User.first
    Emailer.reset_password(user.id)
  end

  def forgot_password
    password_reset = ResetPassword.create! do |passwd|
      passwd.email = "reset#{SecureRandom.hex(20)}@example.com"
      passwd.user = User.first
      passwd.reset_code = SecureRandom.hex(20)
    end
    Emailer.forgot_password(password_reset.id)
  end

  def project_membership_notification
    invitation = Invitation.new do |i|
      i.user = User.first
      i.invited_user = User.last
      i.project = Project.first
    end
    invitation.save!
    Emailer.project_membership_notification(invitation.id)
  end

  def project_invitation
    invitation = Invitation.new do |i|
      i.token = SecureRandom.hex(20)
      i.user = User.first
      i.invited_user = User.last
      i.project = Project.first
    end
    invitation.is_silent = true
    invitation.save!

    Emailer.project_invitation(invitation.id)
  end

  def accepted_project_invitation
    invitation = Invitation.new do |i|
      i.token = SecureRandom.hex(20)
      i.user = User.first
      i.invited_user = User.last
      i.project = Project.first
    end
    invitation.is_silent = true
    invitation.save!

    Emailer.accepted_project_invitation(invitation.invited_user.id, invitation.id)
  end

  def confirm_email
    user = User.first
    Emailer.confirm_email(user.id)
  end

  def public_download
    upload = Upload.new do |u|
      u.asset_file_name = "Somefile.txt"
      u.user = User.first
      u.project = Project.first
    end
    upload.save!

    Emailer.public_download(upload.id, "someone@teambox.com", "upload")
  end
end
