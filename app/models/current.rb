class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :projects_and_people

  delegate :user, to: :session, allow_nil: true
end
