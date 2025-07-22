class CurrentProjectsAndPeople
  def initialize(projects)
    @projects = projects
  end

  def people_for_project(project)
    return Person.none unless project
    @projects.find { |p| p.id == project.id }&.people
  end

  def people_for_project_without_current_user(project)
    people_for_project(project).where.not(user_id: Current.user.id)
  end
end
