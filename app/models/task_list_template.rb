class TaskListTemplate < ActiveRecord::Base
  belongs_to :organization
  has_many :tasks, class_name: "TaskListTemplateTask", dependent: :destroy
  accepts_nested_attributes_for :tasks, allow_destroy: true, reject_if: :all_blank

  validates_length_of :name, maximum: 255, minimum: 1
  validates_presence_of :organization

  default_scope -> { order(position: :asc, id: :desc) }

  positioned on: :organization

  def create_task_list(project, user)
    task_list = project.task_lists.new
    task_list.name = name
    task_list.user = user
    if task_list.save
      tasks.each do |task|
        task_list.tasks << Task.new(name: task.name, comments_attributes: [ { body: task.description } ], user: user)
      end
    end
    task_list
  end

  def to_json(options = {})
    { id: id,
      name: ERB::Util.html_escape(name),
      organization: ERB::Util.html_escape(organization.permalink),
      tasks: tasks.collect { |t| { title: ERB::Util.html_escape(t.name), desc: ERB::Util.html_escape(t.description) } }
    }
  end
end
