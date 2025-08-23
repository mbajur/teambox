require 'clockwork'
require './config/boot'
require './config/environment'
require 'active_support/time' # Allow numeric durations (eg: 1.minutes)

module Clockwork
  every(1.hour, 'user.daily_task_reminders') do
    User.send_daily_task_reminders
  end

  every(1.hour, 'person.send_all_digest') do
    Person.send_all_digest
  end
end
