require 'rails_helper'

describe TaskList, type: :model do
  subject { FactoryBot.create(:task_list) }

  xit { should belong_to(:project) }
  it { should belong_to(:page).optional }
  it { should have_many(:comments) }
  it { should have_many(:tasks) }

  xit { should validate_length_of(:name).is_at_least(1).is_at_most(255) }

  describe "factories" do
    it "should generate a valid task list" do
      task_list = FactoryBot.create(:task_list)
      task_list.valid?.should be true
    end
  end

  describe "references" do
    it "should reference the correct tasks" do
      task_list = FactoryBot.create(:task_list)
      task_list.references[:task].should == nil
      resolved_task = FactoryBot.create(:task, :name => "Go to RailsConf", :task_list => task_list, :status => Task::STATUSES[:resolved])
      unresolved_task = FactoryBot.create(:task, :name => "Leave RailsConf", :task_list => task_list)
      task_list.reload.tasks.length.should == 2

      task_list.reference_task_objects = :task_ids
      task_list.task_ids.should == task_list.references[:task_list_task]
      task_list.reference_task_objects = :unarchived_task_ids
      task_list.unarchived_task_ids.should == task_list.references[:task_list_task]
      task_list.reference_task_objects = :archived_task_ids
      task_list.archived_task_ids.should == task_list.references[:task_list_task]
    end
  end

  describe "when deleted" do
    it "should delete its tasks" do
      task_list = FactoryBot.create(:task_list, :name => "Be an excellent Rails dev.")
      nice_task = FactoryBot.create(:task, :name => "Go to RailsConf", :task_list => task_list)
      task_list.destroy
      lambda { Task.find(nice_task.id) }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
