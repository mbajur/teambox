class Note < RoleRecord
  include Immortal
  include PageWidget
  extend HtmlFormatting

  belongs_to :page
  belongs_to :project
  has_one :page_slot, as: :rel_object

  formats_attributes :body

  attr_accessor :deleted
  attr_accessor :updated_by

  before_destroy :clear_slot
  after_create :save_slot, :log_create
  after_update :touch_updated

  def log_create
    project.log_activity(self, 'create', updated_by.id) if updated_by
  end

  def touch_updated
    project.log_activity(self, 'edit', updated_by.id) if updated_by
  end

  def slot_view
    'notes/note'
  end

  def to_s
    name
  end
end
