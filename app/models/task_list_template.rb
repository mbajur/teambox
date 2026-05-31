class TaskListTemplate < ActiveRecord::Base
  belongs_to :organization

  serialize :raw_tasks, coder: JSON

  validates_length_of :name, maximum: 255, minimum: 1
  validates_presence_of :organization

  default_scope -> { order(position: :asc, id: :desc) }

  positioned on: :organization

  def tasks
    raw_tasks || []
  end

  def tasks=(value)
    self.raw_tasks = value
  end

  def create_task_list(project, user)
    task_list = project.task_lists.new
    task_list.name = name
    task_list.user = user
    if task_list.save
      tasks.each do |task|
        task_list.tasks << Task.new(name: task[0], comments_attributes: [ { body: task[1] } ], user: user)
      end
    end
    task_list
  end

  def to_json(options = {})
    { id: id,
      name: ERB::Util.html_escape(name),
      organization: ERB::Util.html_escape(organization.permalink),
      tasks: tasks.collect { |t| { title: ERB::Util.html_escape(t.first), desc: ERB::Util.html_escape(t.second) } }
    }
  end
end
