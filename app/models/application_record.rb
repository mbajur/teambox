class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.new_by_user(user, attributes = {})
    new(attributes) { |obj| obj.user = user; yield(obj) if block_given? }
  end

  def self.build_by_user(user, attributes = {})
    build(attributes) { |obj| obj.user = user; yield(obj) if block_given? }
  end

  def self.create_by_user(user, attributes = {})
    create(attributes) { |obj| obj.user = user; yield(obj) if block_given? }
  end

  # Needed for backward compatibility with NotificationsObserver
  def transaction_include_action?(action)
    case action.to_sym
    when :create
      new_record? || (previous_changes.key?("id") && !destroyed?)
    when :update
      persisted? && changed?
    when :destroy
      destroyed?
    else
      false
    end
  end
end
