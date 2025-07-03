class Address < ActiveRecord::Base
  belongs_to :card

  TYPES = [ "Work", "Home", "Other" ]

  def get_type
    TYPES[account_type]
  end
end
