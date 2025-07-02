class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  scope :with_deleted, -> { where(deleted: [ true, false ]) }

  def self.new_by_user(user, attributes = {})
    new(attributes) { |obj| obj.user = user; yield(obj) if block_given? }
  end

  def self.build_by_user(user, attributes = {})
    build(attributes) { |obj| obj.user = user; yield(obj) if block_given? }
  end

  def self.create_by_user(user, attributes = {})
    create(attributes) { |obj| obj.user = user; yield(obj) if block_given? }
  end

  def self.find_with_deleted(id)
    self.with_deleted.find(id)
  end
end
