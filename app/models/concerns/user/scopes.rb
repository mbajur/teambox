module User::Scopes
  extend ActiveSupport::Concern

  included do
    scope :wants_task_reminder_email, -> { where(wants_task_reminder: true) }
    scope :wants_task_notifications, -> { where(notify_tasks: true) }
    scope :confirmed, -> { where(confirmed_user: true) }
    scope :with_deleted, -> { where(deleted: [ true, false ]) }
  end

  class_methods do
    def in_time_zone(zone)
      self.where(time_zone: zone)
    end
  end
end
