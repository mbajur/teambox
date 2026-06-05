require 'rails_helper'

describe TaskListTemplate, type: :model do
  subject { FactoryBot.create(:task_list_template) }

  it { should belong_to(:organization) }
  it { should have_many(:tasks) }
  it { should validate_length_of(:name).is_at_least(1).is_at_most(255) }
  xit { should validate_presence_of(:name) }

  describe "factories" do
    it "should generate a valid task list template" do
      template = FactoryBot.create :task_list_template
      template.reload.should be_valid
      template.name.should == 'I will come up with a better name later'
      template.tasks.count.should == 3
      template.organization.should_not be_nil
    end

    it "should need an organization" do
      template = FactoryBot.build(:task_list_template, organization: nil)
      template.should_not be_valid
    end
  end

  it "should return an empty collection if no tasks" do
    template = FactoryBot.create(:task_list_template)
    template.tasks.destroy_all
    template.tasks.reload.should be_empty
  end

  it "should return TaskListTemplateTask objects" do
    template = FactoryBot.create(:task_list_template)
    template.tasks.each { |t| t.class.should == TaskListTemplateTask }
  end

  it "should contain task descriptions if provided" do
    template = FactoryBot.create(:complete_task_list_template)
    template.tasks.each { |t| t.description.should_not be_nil }
  end

  describe "creating task lists" do
    before do
      @user = FactoryBot.create :user
      @project = FactoryBot.create :project, user: @user
    end

    it "should create a task list from a template without comments" do
      template = FactoryBot.create :task_list_template, organization: @project.organization
      list = template.create_task_list(@project, @user)
      list.tasks.collect { |t| t.name }.should == template.tasks.collect { |t| t.name }
    end

    it "should create a task list with comments from a complete template" do
      template = FactoryBot.create :complete_task_list_template, organization: @project.organization
      list = template.create_task_list(@project, @user).reload
      list.tasks.collect { |t| [ t.name, t.comments.first.try(:body) ] }.should == template.tasks.collect { |t| [ t.name, t.description ] }
    end

    it "should set the correct user" do
      template = FactoryBot.create :complete_task_list_template, organization: @project.organization
      list = template.create_task_list(@project, @user).reload
      list.user.should == @user
      list.tasks.each { |t| t.user.should == @user }
      list.tasks.each { |t| t.comments.each { |c| c.user.should == @user } }
    end

    it "should set the correct project" do
      template = FactoryBot.create :complete_task_list_template, organization: @project.organization
      list = template.create_task_list(@project, @user).reload
      list.project.should == @project
    end
  end
end
