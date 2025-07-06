# @todo copy all methods from
#   https://github.com/redbooth/immortal/blob/master/lib/immortal.rb
module Immortal
  extend ActiveSupport::Concern

  COLUMN_NAME = "deleted".freeze

  included do
    scope(:mortal, -> { where(COLUMN_NAME => false) })
    scope(:immortal, -> { where(COLUMN_NAME => true) })
    scope :with_deleted, -> { unscoped.where(deleted: [ true, false ]) }

    default_scope -> { mortal } if arel_table[COLUMN_NAME]

    alias_method :mortal_destroy, :destroy
    alias_method :destroy, :immortal_destroy
  end

  class_methods do
    def find_with_deleted(id)
      without_default_scope do
        find(id)
      end
    end

    def find_only_deleted(id)
      without_default_scope do
        find(id)
      end
    end

    # Add with/how_deleted singular association readers
    def belongs_to_mortal(name, scope = nil, options = {})
      reflection = Immortal::BelongsToBuilder.build(self, name, scope, options)
      ActiveRecord::Reflection.add_reflection self, name, reflection
    end

    def immortal?
      included_modules.include?(::Immortal::InstanceMethods)
    end

    def without_default_scope
      where_clause = (current_scope || unscoped).where_values_hash.except(COLUMN_NAME)

      unscoped.where(where_clause).scoping do
        yield
      end
    end

    def exists?(id = false)
      mortal.exists?(id)
    end

    def count_with_deleted(*args)
      without_default_scope do
        count(*args)
      end
    end

    def count_only_deleted(*args)
      without_default_scope do
        immortal.count(*args)
      end
    end

    def where_with_deleted(*conditions)
      without_default_scope do
        where(*conditions)
      end
    end

    def where_only_deleted(*conditions)
      without_default_scope do
        immortal.where(*conditions)
      end
    end

    def immortal_delete_all(conditions = nil)
      unscoped.where(conditions).update_all(COLUMN_NAME => 1)
    end

    def delete_all!(*args)
      unscoped.mortal_delete_all(*args)
    end

    def undeleted_clause_sql
      unscoped.mortal.constraints.first.to_sql
    end

    def deleted_clause_sql
      unscoped.where(arel_table[COLUMN_NAME].eq(true)).constraints.first.to_sql
    end
  end

  def immortal_destroy
    with_transaction_returning_status do
      run_callbacks :destroy do
        destroy_without_callbacks
      end
    end
  end

  def destroy!
    mortal_destroy
  end

  def destroy_without_callbacks
    scoped_record.update_all(
      COLUMN_NAME => true,
      updated_at: current_time_from_proper_timezone
    )

    @destroyed = true
    reload
    freeze
  end

  def recover!
    scoped_record.update_all(
      COLUMN_NAME => false,
      updated_at: current_time_from_proper_timezone
    )

    @destroyed = false
    reload
  end

  private

  # @return [ActiveRecord::Relation]
  def scoped_record
    self.class.unscoped.where(id: id)
  end

  def current_time_from_proper_timezone
    Time.zone.name == "UTC" ? Time.now.utc : Time.current
  end
end
