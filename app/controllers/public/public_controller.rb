class Public::PublicController < ApplicationController
  skip_before_action :touch_user, :verify_authenticity_token
  # skip_before_action :login_required
  before_action :set_english_locale
  before_action :load_public_projects

  layout "public_projects"

  protected

    def set_english_locale
      I18n.locale = "en"
    end

    def load_project
      project_id = params[:project_id] || params[:id]
      if project_id
        @project = Project.find_by_permalink(project_id)
        return render text: "Unexisting project" unless @project
        render text: "Not a public project" unless @project.public
      end
    end

    def load_public_projects
      @projects = current_user ? current_user.projects.where(public: true) : Project.none
    end
end
