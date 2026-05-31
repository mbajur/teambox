class Divider < RoleRecord
  include Immortal
  include PageWidget

  belongs_to :page
  belongs_to :project
  has_one :page_slot, as: :rel_object

  attr_accessor :deleted

  before_destroy :clear_slot
  after_create :save_slot
  after_update :touch_updated

  def touch_updated
    page.update_attribute(:updated_at, Time.now)
  end

  def slot_view
    "dividers/divider"
  end

  def to_s
    name
  end
end
