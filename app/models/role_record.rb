class RoleRecord < ApplicationRecord
  self.abstract_class = true

  belongs_to :project
  belongs_to :user, optional: true

  def owner?(u)
    user == u
  end

  def observable?(user)
    project.observable?(user)
  end

  def editable?(user)
    project.editable?(user)
  end

  def self.grab_name(id)
    e = self.find(id, select: "name")
    e = e.nil? ? "" : e.name
  end
end
