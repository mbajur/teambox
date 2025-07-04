class Conversation < RoleRecord
  include Immortal

  # needed for `truncate`
  include ActionView::Helpers::TextHelper

  include Watchable

  include Conversation::Tasks
  include Conversation::Conversions

  attr_accessor :is_importing, :updating_user

  has_one  :first_comment, -> { order("created_at ASC") }, class_name: "Comment", as: :target
  has_many :recent_comments, -> { order("created_at DESC").limit(2) }, class_name: "Comment", as: :target

  has_many :uploads
  has_many :comments, -> { order("created_at DESC") }, as: :target, dependent: :destroy

  accepts_nested_attributes_for :comments, allow_destroy: false,
    reject_if: lambda { |comment| comment["body"].blank? }

  validates_presence_of :user
  validates_presence_of :name, message: :no_title, unless: :simple?

  validate :check_comments_presence, on: :create, unless: :is_importing

  scope :only_simple, -> { where(simple: true) }
  scope :not_simple, -> { where(simple: false) }
  scope :recent, lambda { |num| limit(num).order("updated_at desc") }
  scope :with_deleted, -> { where(deleted: [ true, false ]) }

  before_validation :set_comments_target
  before_validation :set_comments_author, if: :updating_user
  before_update :set_simple
  after_create :log_create, :update_user_stats
  after_destroy :clear_targets

  def self.find_with_deleted(id)
    self.with_deleted.find(id)
  end

  def set_simple
    self.simple = false if simple? and name_changed? and !name.nil?
    true
  end

  def log_create
    project.log_activity(self, "create")
  end

  def clear_targets
    Activity.where(target_id: self.id, target_type: self.class.to_s).destroy_all
  end

  def owner?(u)
    user == u
  end

  def name=(value)
    value = nil if value.blank?
    self[:name] = value
  end

  def body=(value)
    self.comments_attributes = [ { body: value } ] unless value.nil?
  end

  def references
    refs = { users: [ user_id ], projects: [ project_id ] }
    refs[:comment] = [ first_comment.id ] + recent_comment_ids
    refs
  end

  def to_s
    name || ""
  end

  def is_visible?(user)
    !is_private or watchers.include? user
  end

  def self.from_github(payload)
    commits = payload["commits"]
    branch_name = GithubIntegration::Parser.get_branch_name_from_ref(payload["ref"])

    body = GithubIntegration::Builder.comment_body_from_payload_commits(commits.first(10), payload)
    body << "And #{commits.size - 10} more commits" if commits.size > 10

    self.create!(name: "New code on #{branch_name} branch", body: body, simple: true) do |conversation|
      if commits.any?
        author_name_and_email = GithubIntegration::Parser.get_author_from_commits(commits)
        author = conversation.project.users.detect { |u| u.email == author_name_and_email[:email] || u.name == author_name_and_email[:name] }
      end
      conversation.user = author || conversation.project.hook_user
      yield conversation if block_given?
    end
  end

  protected

  def check_comments_presence
    unless comments.any?
      errors.add :comments, :must_have_one
    end
  end

  def set_comments_author # before_validation
    comments.select(&:new_record?).each do |comment|
      comment.user = updating_user
    end
    true
  end

  def set_comments_target
    comments.each { |c| c.target = self if c.target.nil? or c.new_record? }
  end

  def update_user_stats
    # user.increment_stat "conversations" if user
  end
end
