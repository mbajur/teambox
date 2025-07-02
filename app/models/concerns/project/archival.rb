module Project::Archival
  extend ActiveSupport::Concern

  included do
    scope :archived, -> { where(archived: true) }
    scope :unarchived, -> { where(archived: false) }
  end

  def archive!
    update_attribute(:archived, true)
  end
end
