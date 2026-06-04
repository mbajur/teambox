require "digest/sha1"

# A User model describes an actual user, with his password and personal info.
# A Person model describes the relationship of a User that follows a Project.

class User < ApplicationRecord
  include Immortal
  include Metadata
  extend Metadata::Defaults

  include User::Activation
  include User::Authentication
  # include User::Avatar
  include User::Badges
  include User::Conversations
  include User::RecentProjects
  include User::Roles
  # include User::Rss
  include User::Scopes
  include User::Validation
  include User::TaskReminders
  include User::Stats
  include User::Oauth

  include Rails.application.routes.url_helpers

  has_secure_password

  # concerned_with  :activation,
  #                 :avatar,
  #                 :authentication,
  #                 :conversions,
  #                 :recent_projects,
  #                 :roles,
  #                 :rss,
  #                 :scopes,
  #                 :validation,
  #                 :task_reminders,
  #                 :stats,
  #                 :badges,
  #                 :oauth

  has_many :projects_owned, class_name: "Project", foreign_key: "user_id"
  has_many :comments
  has_many :conversations
  has_many :task_lists
  has_many :pages
  has_many :people
  has_many :notifications, dependent: :destroy
  has_many :projects, -> { order(name: :asc) }, through: :people
  has_many :invitations, foreign_key: "invited_user_id"
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :user_id
  has_many :activities
  has_many :uploads
  has_many :app_links, dependent: :destroy
  has_many :memberships
  has_many :teambox_datas
  has_many :watchers, dependent: :destroy
  has_many :sessions, dependent: :destroy

  has_many :organizations, through: :memberships
  has_many :admin_organizations, -> { where("memberships.role" => Membership::ROLES[:admin]) }, through: :memberships, source: :organization

  belongs_to :invited_by, class_name: "User", optional: true

  has_one :card
  accepts_nested_attributes_for :people, update_only: true, reject_if: proc { |attributes| (attributes.keys - %w[id digest watch_new_conversation watch_new_task watch_new_page]).any? }
  accepts_nested_attributes_for :card

  default_scope { order("users.updated_at DESC") }
  scope :in_alphabetical_order, -> { order("users.first_name ASC") }

  # attr_accessor :password, :password_confirmation

  # attr_accessor :login,
  #               :email,
  #               :first_name,
  #               :last_name,
  #               :biography,
  #               :password,
  #               :password_confirmation,
  #               :old_password,
  #               :time_zone,
  #               :locale,
  #               :first_day_of_week,
  #               :betatester,
  #               :card_attributes,
  #               :notify_conversations,
  #               :notify_tasks,
  #               :notify_pages,
  #               :splash_screen,
  #               :wants_task_reminder,
  #               :keyboard_shortcuts,
  #               :digest_delivery_hour,
  #               :instant_notification_on_mention,
  #               :default_digest,
  #               :default_watch_new_task, :default_watch_new_conversation, :default_watch_new_page,
  #               :people_attributes,
  #               :google_calendar_url_token,
  #               :auto_accept_invites

  attr_accessor :activate, :old_password

  before_validation :sanitize_name
  validate :old_password_correct, if: -> { password_digest_changed? && persisted? && !activate }
  before_destroy :rename_as_deleted

  before_create :init_user
  after_create :clear_invites
  before_save :update_token

  def update_token
    self.recent_projects_ids ||= []
    # self.rss_token ||= generate_rss_token
    self.visited_at ||= Time.now
  end

  def init_user
    if invitation = Invitation.find_by_email(email)
      self.invited_by = invitation.user
      invitation.user.update_attribute :invited_count, (invitation.user.invited_count + 1)
    end
    self.card ||= build_card
    self.splash_screen = true
  end

  def clear_invites
    # send_activation_email unless self.confirmed_user

    if invitations = Invitation.where(email: email)
      for invitation in invitations
        invitation.accept(self)
        invitation.destroy
      end
    end
  end

  # This should be a user setting in Settings
  #
  # We are auto-accepting all invites, which could lead to spam problems
  # In the future we should add a per-user setting to not autoaccept invites
  # (by default users will autoaccept invites)
  def auto_accept_invites
    self[:auto_accept_invites]
  end

  def self.find_by_username_or_email(login)
    return unless login
    if login.include? "@" # usernames are not allowed to contain '@'
      find_by_email(login.downcase)
    else
      find_by_login(login.downcase)
    end
  end

  def to_s
    name
  end

  def to_param
    login_was # in case it changes but is not yet saved
  end

  def visited_at
    read_attribute(:visited_at) || updated_at
  end

  def locale
    if I18n.available_locales.map(&:to_s).include? self[:locale]
      self[:locale]
    else
      I18n.default_locale.to_s
    end
  end

  def projects_shared_with(user)
    self.projects & user.projects
  end

  def shares_invited_projects_with?(user)
    Invitation.where(project_id: user.project_ids, invited_user_id: self.id).count.positive?
  end

  def users_with_shared_projects
    ids = self.projects.except(:order).order("id DESC").map(&:user_ids).flatten
    ids += Invitation.where(project_id: self.project_ids).select("user_id").map(&:user_id)

    User.where({ id: ids.uniq })
  end

  def new_comment(user, target, comment)
    self.comments.new(comment) do |comment|
      comment.user_id = user.id
      comment.target = target
    end
  end

  def log_activity(target, action, creator_id = nil)
    creator_id ||= target.user_id
    Activity.log(nil, target, action, creator_id)
  end

  def update_visited_at
    if visited_at.nil? or (Time.now - visited_at) >= 12.hours
      update_attribute(:visited_at, Time.now)
    end
  end

  def person_for(project)
    self.people.find_by_project_id(project.id)
  end

  def member_for(organization)
    self.memberships.find_by_organization_id(organization.id)
  end

  def watching?(object)
    object.has_watcher? self
  end

  def utc_offset
    @utc_offset ||= ActiveSupport::TimeZone[time_zone].try(:utc_offset) || 0
  end

  def in_project(project)
    project.people.find_by_user_id(self)
  end

  def contacts
    conditions = [ "project_id IN (?)", Array(self.projects).collect { |p| p.id } ]
    user_ids = Person.find(:all,
      select: "user_id",
      conditions: conditions,
      limit: 300).collect { |p| p.user_id }.uniq
    conditions = [ "id IN (?) AND deleted = ? AND id != (?)", user_ids, false, self.id ]
    User.find(:all,
      conditions: conditions,
      order: "updated_at DESC",
      limit: 60)
  end

  def active_projects_count
    projects.unarchived.count
  end

  def can_create_project?
    true
  end

  DELETED_TAG = "deleted"
  DELETED_REGEX = /#{DELETED_TAG}\d+__(.*)/i

  def rename_as_deleted
    tag = find_available_deleted_tag

    update!(login: "#{tag}#{login}") unless login =~ DELETED_REGEX
    update(email: "#{tag}#{email}") unless email =~ DELETED_REGEX
  end

  def rename_as_active
    login =~ DELETED_REGEX
    update_attribute :login, Regexp.last_match(1).to_s if login =~ DELETED_REGEX
    update_attribute :email, Regexp.last_match(1).to_s if email =~ DELETED_REGEX
  end

  def self.find_available_login(proposed_login = nil)
    proposed_login ||= "user"
    counter = 0
    begin
      counter += 1
      login = "#{proposed_login}#{counter == 1 ? nil : counter}"
    end while User.where_with_deleted("login LIKE ?", login).first
    login
  end

  def active_project_ids
    @active_project_ids ||= Person.where(user_id: id).joins(:project).where(projects: { archived: false }).collect(&:id)
  end

  def pending_tasks
    return Task.none if active_project_ids.empty?

    Task
      .where(status: Task::ACTIVE_STATUS_CODES)
      .where(assigned_id: active_project_ids)
      .includes(:project)
      .unscope(:order)
      .order(
        Arel.sql("CASE WHEN tasks.urgent THEN 0 ELSE 1 END ASC"),  # urgent first
        Arel.sql("COALESCE(tasks.due_on, '#{1.year.from_now.to_date}') ASC"),  # earlier due dates first
        Arel.sql("tasks.id ASC")  # older tasks first
      )
  end

  def nearest_pending_tasks
    pending_tasks.reject { |t| t.due_on && t.due_on > 2.weeks.from_now.to_datetime }
  end

  def clear_pending_tasks!
    Rails.cache.delete("pending_tasks.#{id}")
  end

  def tasks_counts_update
    assigned_tasks = Task.assigned_to(self)
    # we do t.statys && t.status < 3 because some tasks might be
    self.assigned_tasks_count  = assigned_tasks.select { |t| t.status == 1 }.length
    self.completed_tasks_count = assigned_tasks.select { |t| t.status == 3 }.length
    self.save
  end

  def users_for_user_map
    @users_for_user_map ||= self.organizations.map { |o| o.users + o.users_in_projects }.flatten.uniq
  end

  def keyboard_shortcuts
    !!settings["keyboard_shortcuts"]
  end

  def keyboard_shortcuts=(v)
    self.settings = { "keyboard_shortcuts" => v == "1" }
  end

  def collapse_activities
    # true if unset, true if true, false if false
    settings["collapse_activities"] == false ? false : true
  end

  def google_calendar(gcal = nil)
    gcal = gcal || get_calendar_app
    return nil if gcal.nil?

    unless google_calendar_url_token.blank?
      Rails.logger.debug("Using existing calendar #{google_calendar_url_token}")
      gcal.find(google_calendar_url_token)
    else
      Rails.logger.debug("Creating new Google calendar for user")
      calendar = gcal.create_calendar(GoogleCalendar::Calendar.new(title: "Teambox"))

      Rails.logger.debug("Setting google_calendar_url_token to #{calendar.url_token}")
      self.update_attributes!(google_calendar_url_token: calendar.url_token)
      calendar
    end
  end

  def get_calendar_app
    consumer = get_google_calendar_provider
    return nil if consumer.nil?

    app_link = self.app_links.find_by_provider("google")
    if app_link.nil?
      Rails.logger.debug "The user has not linked their Google account, calendar entry will not be created"
      return nil
    end

    GoogleCalendar.new(app_link.credentials["token"], app_link.credentials["secret"], consumer)
  end

  def avatar?
    Rails.logger.warn "avatar? method has been hardcoded in User model"
    false
  end

  def avatar_or_gravatar_path(size, secure = false)
    (avatar? ? avatar.url(size) : gravatar(size, secure)).tap do |avatar_url|
      avatar_url.sub! "http:", "https:" if secure
    end
  end

  def avatar_or_gravatar_url(size = :thumb, secure = false)
    avatar_or_gravatar_path(size, secure).tap do |url|
      if url.starts_with? "http"
        scheme = secure ? "https:" : "http:"
        url.sub("http:", scheme)
      else
        scheme = secure ? "https:" : "http:"
        url.replace "%s//%s%s" % [ scheme, Rails.configuration.teambox.app_domain, url ]
      end
    end
  end

  private

  def gravatar_id
    Digest::MD5.hexdigest email.downcase
  end

  def gravatar(size, secure = false, default = Rails.configuration.teambox.gravatar_default)
    (secure ? "https://secure." : "http://www.").tap do |url|
      url << "gravatar.com/avatar/#{gravatar_id}?size=#{User::Avatar::AvatarSizes[size][0]}"
      url << "&default=#{default}" if default
    end
  end

  protected

    def find_available_deleted_tag
      counter = 0
      begin
        counter += 1
        tag = "#{DELETED_TAG}#{counter}__"
        user = User.with_deleted.where("login LIKE '#{tag}#{login}' OR email LIKE '#{tag}#{email}'").first
      end while user
      tag
    end

    def sanitize_name
      self.first_name = first_name.blank?? nil : first_name.squish
      self.last_name = last_name.blank?? nil : last_name.squish
    end

    def get_google_calendar_provider
      oauth_info = Rails.configuration.teambox.providers.detect { |p| p.provider == "google" }
      if oauth_info.nil?
        Rails.logger.debug "There is no Google provider, calendar entry will not be created"
        return nil
      end
      OAuth::Consumer.new(oauth_info.key, oauth_info.secret, GoogleCalendar::RESOURCES)
    end

    def old_password_correct
      original_digest = password_digest_was || password_digest
      if old_password.blank? || original_digest.blank? || !BCrypt::Password.new(original_digest).is_password?(old_password)
        errors.add(:old_password, "is required")
      end
    end
end
