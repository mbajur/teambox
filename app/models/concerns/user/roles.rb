module User::Roles
  extend ActiveSupport::Concern

  def observable?(user)
    projects_shared_with(user).any? || user == self
  end

  def can_search?
    Rails.configuration.teambox.allow_search
  end
end
