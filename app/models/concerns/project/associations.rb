module Project::Associations
  extend ActiveSupport::Concern

  included do
    belongs_to :user, optional: true
    belongs_to :organization

    accepts_nested_attributes_for :organization

    with_options dependent: :delete_all do |delete|
      delete.has_many :people
      delete.has_many :task_lists, -> { where(page_id: nil) }
      delete.has_many :tasks
      delete.has_many :invitations
      delete.has_many :uploads
      delete.has_many :folders
      delete.has_many :notes
      delete.has_many :dividers
      delete.has_many :watcher_tags, class_name: "Watcher"

      has_many :conversations, -> { order("id DESC") }
      has_many :activities, -> { order("id DESC") }
      has_many :comments, -> { order("id DESC") }
    end

    has_many :pages, dependent: :destroy

    has_many :users, through: :people
    has_many :admins, -> { where("people.role" => Person::ROLES[:admin]) },  through: :people, source: :user

    has_one  :first_comment, -> { order("created_at ASC") }, class_name: "Comment", as: :target
    has_many :recent_comments, -> { order("created_at DESC").limit(2) }, class_name: "Comment", as: :target
  end
end
