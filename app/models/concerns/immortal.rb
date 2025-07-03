# @todo copy all methods from
#   https://github.com/redbooth/immortal/blob/master/lib/immortal.rb
module Immortal
  extend ActiveSupport::Concern

  def delete
    update(deleted: true)
  end
end
