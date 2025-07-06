require 'rails_helper'

describe TasksController, type: :controller do
  include AuthenticatedTestHelper

  before do
    @user = FactoryBot.create(:confirmed_user)
    @project = FactoryBot.create(:project)
    @project.add_user @user
  end

  describe "#create" do
    it "should set the due date" do
      task_list = FactoryBot.create(:task_list, project: @project, user: @user)
      login_as @user

      post :create, params: {
        project_id: @project.permalink,
        task_list_id: task_list.id,
        task: { name: 'This should work', due_on: 'September 30, 2010' }
      }
      # This will be changed when Mislav fixes the bug
      # that prevents due date if the locale is not english,
      # because we'll be sending a date that's not in human form

      task = task_list.tasks.order(created_at: :desc).last
      task.name.should == 'This should work'
      task.due_on.should == 'September 30, 2010'.to_date
    end
  end
end
