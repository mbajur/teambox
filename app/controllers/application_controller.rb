class ApplicationController < ActionController::Base
  # include AuthenticatedSystem
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :resume_session,
                :set_locale,
                :set_client,
                :load_project,
                :load_organizations,
                :touch_user,
                :belongs_to_project?,
                :load_community_organization,
                :add_chrome_frame_header

  private

  def check_permissions
    unless @current_project.editable?(current_user)
      render text: "You don't have permission to edit/update/delete within \"#{@current_project.name}\" project", status: :forbidden
    end
  end

  def handle_cancan_error(exception)
    if request.xhr?
      head :forbidden
    else
      flash[:error] = exception.message
      redirect_to root_url
    end
  end

  def handle_no_permissions
    render text: "You don't have permission to edit/update/delete within \"#{@current_project.name}\" project", status: :forbidden
  end

  def rss_token
    unless params[:rss_token].nil? or !%w[rss ics].include?(params[:format])
      user = User.find_by_rss_token(params[:rss_token])
      set_current_user user if user
    end
  end

  def belongs_to_project?
    if @current_project and authenticated?
      if current_user.projects.exists? @current_project.id
        # user is a project member
        unless @current_project.archived?
          current_user.add_recent_project(@current_project)
        end
      elsif @current_project.invitations.exists?(invited_user_id: current_user)
        # there is an invitation pending for accept
        redirect_to project_invitations_path(@current_project)
      elsif @current_project.organization.is_admin?(current_user)
        nil
      else
        # sorry, no dice
        if [ :rss, :ics ].include? request.formats.map(&:symbol)
          render nothing: true
        else
          respond_to do |f|
            f.any(:html, :m, :print) { render "projects/not_in_project", status: :forbidden }
          end
        end
      end
    end
  end

  def load_project
    if project_id = params[:project_id] || params[:id]
      unless @current_project = Project.find_by_id_or_permalink(project_id)
        flash[:error] = t("not_found.project", id: project_id)
        redirect_to projects_path
      end
    end
  end

  # When you only belong to one organization, every page will be branded with its logo and colors.
  # If you belong to 2+ organizations, common pages will not be branded and others will be organization branded
  def load_organizations
    if authenticated?
      @organizations = current_user.organizations
      @organization = case @organizations.size
      when 0
        current_user.projects.try(:first).try(:organization)
      when 1
        @organizations.first
      else
        @current_project.try(:organization)
      end
    end
  end

  def set_locale
    locale = authenticated? ? current_user.locale : (params[:locale] || user_agent_locale)
    I18n.locale = (locale.present? && I18n.available_locales.include?(locale.to_sym)) ? locale : I18n.default_locale
  end

  def user_agent_locale
    unless Rails.env.test? || Rails.env.cucumber?
      user_agent_locales.first
    else
      :en
    end
  end

  LOCALES_REGEX = /\b(#{ I18n.available_locales.join('|') })\b/

  def user_agent_locales
    request.headers["HTTP_ACCEPT_LANGUAGE"].to_s.split(",").map do |s|
      s =~ LOCALES_REGEX && $&
    end
  end

  def fragment_cache_key(key)
    super(key).tap { |str|
      str << "_#{I18n.locale}"
      if authenticated? and current_user.time_zone?
        str << "-#{current_user.time_zone.gsub(/\W/, '')}"
      end
    }
  end

  def touch_user
    current_user.update_visited_at if authenticated?
  end

  def set_page_title
    location_name = "#{params[:action]}_#{params[:controller]}"
    translate_location_name = t("page_title.#{location_name}", default: "")

    if params.has_key?(:id) && [ "show_projects", "edit_projects" ].include?(location_name)
      project_name = @current_project.name
      @page_title = h("#{project_name} — #{translate_location_name}")
    elsif params.has_key?(:project_id)
      project_name = @current_project.name
      name = nil
      case location_name
      when "show_tasks"
          name = @task ? @task.name : nil
      when "show_task_lists"
          name = @task_list ? @task_list.name : nil
      when "show_conversations"
          name = @conversation ? @conversation.name : nil
      when "show_pages"
          name = @page ? @page.name : nil
      end
      @page_title = h("#{project_name} — #{name || translate_location_name}")
    else
      name = nil
      user_name = nil
      case location_name
      when "edit_users"
          user_name = current_user.name
      when "show_users"
          user_name = @user.name
      end
      @page_title = h("#{user_name ? user_name + ' — ' : ''}#{translate_location_name}")
    end
  end

  MobileClients = /(iPhone|iPod|Android|Opera mini|Blackberry|Palm|Windows CE|Opera mobi|iemobile|webOS)/i

  def set_client
    if [ :html, :m ].include?(request.format.try(:to_sym)) and session[:format]
      # Format has been forced by Sessions#change_format
      request.format = session[:format].to_sym
    else
      # We should autodetect mobile clients and redirect if they ask for html
      mobile =   request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][MobileClients]
      mobile ||= request.env["HTTP_PROFILE"] || request.env["HTTP_X_WAP_PROFILE"]
      if mobile and request.format == :html
        request.format = :m
      end
    end
  end

  def mobile?
    request.format == :m
  end
  helper_method :mobile?

  def iframe?
    params[:iframe] == "true"
  end

  def output_errors_json(record)
    if request.xhr?
      response.content_type = Mime::JSON
      render json: record.errors.as_json, status: 400
    elsif iframe?
      response.content_type = Mime::HTML
      render template: "shared/iframe_error", layout: false, locals: { data: record.errors.as_json }
    end
  end

  def split_events_by_date(events, start_date = nil)
    start_date ||= Date.today.monday.to_date
    split_events = Array.new
    Array(events).each do |event|
      if (event.due_on - start_date) >= 0
        split_events[(event.due_on - start_date)] ||= []
        split_events[(event.due_on - start_date)] << event
      end
    end
    split_events
  end

  def calculate_position(obj)
    options = {}
    if pos = params[:position].presence
      options[:id] = pos[:slot].to_i
      if options[:id] < 0
        options[:id] = 0
        options[:before] = false
        options[:footer] = true
      else
        options[:before] = options[:id] == 0 ? true : (pos[:before].to_i == 1)
        options[:footer] = false
      end
    else
      options[:id] = nil
      options[:before] = true
      options[:footer] = false
    end
    obj.slot_insert = options
  end

  def signups_enabled?
    !Rails.configuration.teambox.community || User.count == 0
  end

  def time_tracking_enabled?
    Rails.configuration.teambox.allow_time_tracking || false
  end
  helper_method :time_tracking_enabled?

  def load_community_organization
    if authenticated? and Rails.configuration.teambox.community
      @community_organization = Organization.first
      @community_role = if @community_organization
        role_id = @community_organization.memberships.find_by_user_id(current_user.id).try(:role)
        Membership::ROLES.index(role_id)
      end
    end
  end

  def h(text)
    ERB::Util.h(text)
  end

  def add_chrome_frame_header
    headers["X-UA-Compatible"] = "chrome=1" if chrome_frame? && request.format == :html
  end

  def chrome_frame?
    request.user_agent =~ /chromeframe/
  end
  helper_method :chrome_frame?

  def set_time_zone
    if user_signed_in?
      Time.use_zone(current_user.time_zone) do
        yield
      end
    else
      yield
    end
  end
end
