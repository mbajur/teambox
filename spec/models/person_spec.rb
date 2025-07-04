require 'rails_helper'

describe Person, type: :model do
  # @todo why dependent: :nullify does not work?
  xit "clears the assigned user on tasks when destroyed" do
    task = FactoryBot.create :task
    person = task.project.people.first

    task.assign_to task.project.user
    task.assigned.should == person

    person.destroy

    task.reload.assigned_id.should be_nil
  end

  it "should recover the person when joining if the relation exists and is deleted" do
    project = FactoryBot.create :project
    user = FactoryBot.create :user
    project.add_user(user)

    person_id = project.people.find_by_user_id(user).id
    project.remove_user(user)

    project.reload.people.map(&:id).include?(person_id).should_not == true

    project.add_user(user)
    project.reload.people.map(&:id).include?(person_id).should == true
  end

  it "should generate a delete activity with the correct date when destroyed" do
    project = FactoryBot.create :project
    user = FactoryBot.create :user
    now = Time.now

    Timecop.freeze(now - 10.seconds)
    project.add_user(user)
    Timecop.freeze(now + 10.seconds)

    person = project.people.find_by_user_id(user)
    person.destroy

    activity = project.activities.first
    activity.action.should == 'delete'
    activity.target.should == person
    activity.created_at.to_i.should == Time.now.to_i
  end

  it "should be created" do
    @user = FactoryBot.create(:user)
    @project1 = FactoryBot.create(:project)
    @project2 = FactoryBot.create(:project)
    @user.projects.should be_empty
    @project1.add_user(@user)
    @project2.add_user(@user)
    @user.projects.should include(@project1, @project2)
  end
end
