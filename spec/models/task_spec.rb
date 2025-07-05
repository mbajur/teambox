require 'rails_helper'

describe Task, type: :model do
  it { should belong_to(:project) }
  it { should belong_to(:task_list) }
  it { should belong_to(:page).optional }
  it { should belong_to(:assigned).optional }
  it { should have_many(:comments) }

  xit { should validate_length_of(:name).is_at_least(1).is_at_most(255) }

  describe "a new task" do
    before do
      @project = FactoryBot.create(:project)
      @user = FactoryBot.create(:user)
      @project.add_user(@user)
      @task = FactoryBot.create(:task, project: @project, user: @user)
    end

    it "should add the task creator as a watcher" do
      @task.reload.watchers.should include(@user)
    end

    it "should be created with a new status" do
      @task.status_name.should == :new
    end

    it "should be created with no assigned user" do
      @task.assigned.should be_nil
    end
  end

  it "should allow creation with given statuses" do
    Task::STATUS_NAMES.each do |status_name|
      task = FactoryBot.create(:task, status: Task::STATUSES[status_name])
      task.valid?.should == true
    end
  end

  it "should not allow a user to set an arbitrary status" do
    task = FactoryBot.build(:task, status: 102203)
    task.valid?.should == false
    task.errors[:status].size.should == 1
  end

  it "doesn't break when assigning user on create" do
    task_list = FactoryBot.create(:task_list)
    person = FactoryBot.create(:person, project: task_list.project)
    task = FactoryBot.build(:task, task_list: task_list, project: nil, assigned: person)
    lambda { task.save }.should_not raise_error
  end

  it "errors out on unknown status name" do
    task = FactoryBot.build(:task)
    lambda {
      task.status_name = 'silly'
    }.should raise_error(ArgumentError)
  end

  it "should nilizie due_on only when urgent flag is set" do
    task1 = FactoryBot.create(:task, due_on: Time.now, urgent: false)
    task1.due_on.should_not be_nil

    task2 = FactoryBot.create(:task, due_on: Time.now, urgent: true)
    task2.due_on.should be_nil
  end

  describe "assigning tasks" do
    before do
      @user = FactoryBot.create(:user)
      @task = FactoryBot.create(:task)
    end

    context "valid user" do
      before do
        @task.project.add_user @user
      end

      it "should add the assigned user as a watcher" do
        @task.assign_to @user
        @task.should be_assigned_to(@user)
        @task.reload.has_watcher?(@user).should be true
      end

      it "transitions from new to open" do
        @task.assign_to @user
        @task.status_name.should == :open
      end

      it "doesn't transition from closed to open" do
        @task.status_name = :resolved
        @task.save(validate: false)
        @task.assign_to @user
        @task.status_name.should == :resolved
      end
    end

    it "should not allow assigning it to users outside the project" do
      @task.assign_to @user
      @task.should_not be_assigned_to(@user)
      @task.watchers.should_not include(@user)
    end

    it "validates manually assigned person" do
      project = FactoryBot.create(:project)
      person = FactoryBot.create(:person, user: @user, project: project)

      @task.assigned = person
      @task.should_not be_valid
      @task.errors[:assigned].should eq([ "Assigned user doesn't belong to the project" ])
    end
  end

  describe "assigned_to filter" do
    before do
      @user = FactoryBot.create(:user)

      @projects = [ FactoryBot.create(:project), FactoryBot.create(:project), FactoryBot.create(:archived_project) ]
      people = @projects.map do |project|
        FactoryBot.create(:person, user: @user, project: project)
      end

      FactoryBot.create(:task, project: @projects[0])
      FactoryBot.create(:task, project: @projects[0], assigned: people[0], name: "Feed the cat")
      FactoryBot.create(:resolved_task, project: @projects[0], assigned: people[0])
      FactoryBot.create(:task, project: @projects[1], assigned: people[1], name: "Feed the dog")
      FactoryBot.create(:task, project: @projects[2], assigned: people[2])
    end

    it "gets correct count" do
      Task.active.assigned_to(@user).count.should == 2
    end

    it "gets correct tasks" do
      tasks = Task.active.assigned_to(@user).except(:order).order('name').all
      tasks.map(&:name).should == [ "Feed the cat", "Feed the dog" ]
    end
  end

  describe "creating with comment" do
    it "ignores comments without body and hours" do
      task = FactoryBot.create(:task, comments_attributes: { "0" => { body: "", human_hours: "" } })
      task.comments.should be_empty
    end

    it "saves nested comment with body" do
      task = FactoryBot.create(:task, comments_attributes: { "0" => { body: "I like robots and I cannot lie" } })
      task.comments.count.should == 1
    end

    it "saves nested comment with hours" do
      task = FactoryBot.create(:task, comments_attributes: { "0" => { human_hours: "42m" } })
      task.comments.count.should == 1
    end
  end

  describe "creating with assigned user and first comment" do
    before do
      @task_list = FactoryBot.create(:task_list)
      @project = @task_list.project
      @user = @project.user
    end

    it "tracks the initial assigned user and status" do
      task = @task_list.tasks.create_by_user(@user,
        assigned_id: @project.people.first.id, name: "My task",
        comments_attributes: [ { body: "My comment" } ]
      )

      task.should be_assigned
      task.should be_open

      comment = task.comments.first
      comment.assigned_id.should == task.assigned_id
      comment.status.should == task.status
    end
  end

  describe "updating" do
    it "allows several blank comments with hours" do
      task = FactoryBot.create(:task, comments_attributes: { "0" => { human_hours: "30m" } })
      task.update(comments_attributes: { "0" => { human_hours: "30m" } })
      task.update(comments_attributes: { "0" => { hours: "0.2" } })
      task.comments.count.should == 3
      task.total_hours.should be_within(0.001).of(1.2)
    end

    # @todo i think the comment rejection logic should be moved to the service
    #   object rather than relying on reject_if on accepts_nested_attributes_for
    #   definition. Comments has to be ignored if they are blank, but not when
    #   status of parent task changed. This logic is too complex to rely on
    #   reject_if.
    xit "saves status transitions" do
      task = FactoryBot.create(:task)
      user = FactoryBot.create(:user)
      task.updating_user = user
      task.update(status: "1", comments_attributes: [ { body: "Open Sesame" } ])
      task.should be_open
      task.comments.count.should == 1

      comment = task.comments.last
      comment.user.should == user
      comment.body.should == "Open Sesame"
      comment.previous_status.should == 0
      comment.status.should == 1
      comment.assigned_id.should be_nil

      # We use find rather than reload because the #save_changes_to_comment
      # callback set's an ivar to impede reexecution
      task = Task.find(task.id)
      task.updating_user = user

      task.update(status: "2", comments_attributes: [ { body: "" } ])
      task.status_name.should == :hold
      task.comments.count.should == 2

      comment = task.comments.last
      comment.user.should == user
      comment.body.should be_blank
      comment.previous_status.should == 1
      comment.status.should == 2
      comment.assigned_id.should be_nil
    end

    it "saves completed at" do
      task = FactoryBot.create(:task)
      task.completed_at.should be_nil

      task.update!(status: "1", comments_attributes: [ { body: "" } ])
      task.reload
      task.completed_at.should be_nil

      task.update!(status: "4", comments_attributes: [ { body: "" } ])
      task.reload
      task.completed_at.utc.beginning_of_day.to_date.should == Time.now.utc.beginning_of_day.to_date

      task.update!(status: "2", comments_attributes: [ { body: "" } ])
      task.reload
      task.completed_at.should be_nil

      task.update!(status: "3", comments_attributes: [ { body: "" } ])
      task.reload
      task.completed_at.utc.beginning_of_day.to_date.should == Time.now.utc.beginning_of_day.to_date
    end

    # @todo same as above, move that logic to service object first
    xit "saves assigned user transitions" do
      task = FactoryBot.create(:task)
      user = FactoryBot.create(:user)
      user2 = FactoryBot.create(:user); person2 = FactoryBot.create(:person, user: user2, project: task.project)
      user3 = FactoryBot.create(:user); person3 = FactoryBot.create(:person, user: user3, project: task.project)
      task.updating_user = user
      task.reload.update!(assigned_id: person2.id, comments_attributes: [ { body: "Do it by tomorrow" } ])
      task.should be_assigned_to(user2)
      task.comments.count.should == 1

      comment = task.comments.last
      comment.user.should == user
      comment.body.should == "Do it by tomorrow"
      comment.previous_assigned_id.should be_nil
      comment.assigned_id.should == person2.id

      # We use find rather than reload because the #save_changes_to_comment
      # callback set's an ivar to impede reexecution
      task = Task.find(task.id)
      task.updating_user = user

      task.update(assigned_id: person3.id, comments_attributes: [ { body: "" } ])
      task.should be_assigned_to(user3)
      task.comments.count.should == 2

      comment = task.comments.last
      comment.user.should == user
      comment.body.should be_blank
      comment.previous_assigned_id.should == person2.id
      comment.assigned_id.should == person3.id
    end

    it "displays assigned users even when they are destroyed" do
      # Require with_deleted relationship port in immortal
      user = FactoryBot.create(:mislav)
      project = FactoryBot.create(:project)
      person = FactoryBot.create(:person, project: project, user: user)
      task = FactoryBot.create(:task, project: project)
      task.assigned = person
      task.save!
      person.destroy_without_callbacks # We don't use destroy because we want to avoid the nullify from Person#tasks association
      task.reload.assigned.user.name.should == "Mislav Marohnić"
    end
  end

  describe "due_today scope" do
    before do
      @for_today = FactoryBot.create(:task, due_on: Date.today)
      @for_tomorrow = FactoryBot.create(:task, due_on: Date.today + 1)
    end

    it "should return tasks that are due today" do
      Task.due_today.should include(@for_today)
    end

    it "should not return tasks due tomorrow" do
      Task.due_today.should_not include(@for_tomorrow)
    end
  end

  describe "moving task lists" do
    before do
      @project = FactoryBot.create(:project)
      @user = FactoryBot.create(:user)
      @project.add_user(@user)
      @task_list = @project.create_task_list(@user, name: 'List')
      @task = @project.create_task(@user, @task_list, name: 'Moved task')
    end

    it "should move between task lists" do
      @old_task_list = @task.task_list
      @new_task_list = @project.create_task_list(@user, name: 'Other list')

      @task.task_list.should == @old_task_list
      @task.update(task_list_id: @new_task_list.id).should == true
      @task.reload.task_list.should == @new_task_list
    end

    it "should not move between task lists in different projects" do
      @old_task_list = @task.task_list
      @new_project = FactoryBot.create(:project)
      @new_project.add_user(@user)
      @new_task_list = @new_project.create_task_list(@user, name: 'Other list')

      @task.task_list.should == @old_task_list
      @task.update(task_list_id: @new_task_list.id).should == false
      @task.reload.task_list.should == @old_task_list
    end
  end

  describe "private tasks" do
    it "should mark all related activities as private when created as private" do
      task = FactoryBot.create(:task, is_private: true)
      activities_for_thread(task) { |activity| activity.is_private.should == true }
    end

    # @todo drop paperclip
    it "should update the private status of related activities and comments each time its updated" do
      task = FactoryBot.create(:task, is_private: true)
      comment = task.comments.create_by_user task.user, { body: 'Test' }
      # upload = comment.uploads.build({:asset => mock_uploader('semicolons.js', 'application/javascript', "alert('what?!')")})
      # comment.uploads << upload
      task.save!

      activities_for_thread(task) { |activity| activity.is_private.should == true }
      # task.comments.reload.each{|c| c.is_private.should == true; c.uploads.each{|upload| upload.is_private.should == true} }
      task.update!(is_private: false)
      activities_for_thread(task) { |activity| activity.is_private.should == false }
      # task.comments.reload.each{|c| c.is_private.should == false; c.uploads.each{|upload| upload.is_private.should == false} }
      task.update!(is_private: true)
      activities_for_thread(task) { |activity| activity.is_private.should == true }
      # task.comments.reload.each{|c| c.is_private.should == true; c.uploads.each{|upload| upload.is_private.should == true} }
    end

    it "should still dispatch notification emails when private" do
      watcher = FactoryBot.create(:user)
      # Emailer.should_receive(:send_with_language)

      task = FactoryBot.create(:task, is_private: true)
      task.project.add_user(watcher)
      task.add_watcher(watcher)
      task.comments.create_by_user task.user, { body: 'Nononotify' }
      task.save

      Task.find(task.id).comments.length.should == 1
    end

    it "only comments created by the owner can update is_private" do
      watcher = FactoryBot.create(:user)
      task = FactoryBot.create(:task, is_private: true)
      task.project.add_user(watcher)
      task.add_watcher(watcher)

      task.comments.create_by_user watcher, { body: 'shouldnotwork', is_private: false }
      task.save
      task.reload.is_private.should == true

      task.comments.create_by_user task.user, { body: 'shouldwork', is_private: false }
      task.save
      task.reload.is_private.should == false

      task.comments.create_by_user watcher, { body: 'doesntwork', is_private: true }
      task.save
      task.reload.is_private.should == false

      task.comments.create_by_user task.user, { body: 'reallydoeswork', is_private: true }
      task.save
      task.reload.is_private.should == true
    end

    it "only comments created by the owner can update private_ids" do
      watcher = FactoryBot.create(:user)
      task = FactoryBot.create(:task, is_private: true)
      task.project.add_user(watcher)
      task.add_watcher(watcher)
      current_watchers = Task.find_by_id(task.id).watcher_ids.sort

      task.comments.create_by_user watcher, { body: 'shouldnotwork', is_private: true, private_ids: [ task.user_id ] }
      task.save
      Task.find_by_id(task.id).watcher_ids.should == current_watchers.sort

      task.comments.create_by_user task.user, { body: 'shouldwork', is_private: true, private_ids: [ task.user_id ] }
      task.save
      Task.find_by_id(task.id).watcher_ids.should == [ task.user_id ]
    end

    it "private_ids can only be changed when is_private is set" do
      watcher = FactoryBot.create(:user)
      project = FactoryBot.create(:project)
      task = FactoryBot.create(:task, is_private: true, project: project, user: project.user)
      task = Task.find_by_id(task.id)
      task.project.add_user(watcher)
      task.add_watcher(watcher)
      task = Task.find_by_id(task.id)
      current_watchers = task.watcher_ids.sort

      task.comments.create_by_user task.user, { body: 'shouldnotwork', private_ids: [ task.user_id ] }
      task.save
      Task.find_by_id(task.id).watcher_ids.sort.should == current_watchers.sort

      task.comments.create_by_user task.user, { body: 'shouldreallynotwork', is_private: true, private_ids: [ task.user_id ] }
      task.save
      Task.find_by_id(task.id).watcher_ids.sort.should == [ task.user_id ]
    end

    # @todo that should not be happening on model level, but in service/operation
    xit "setting is_private only works on creation" do
      task_list = FactoryBot.create(:task_list)
      task = task_list.project.create_task(task_list.user, task_list, name: 'Test', is_private: true)
      task.is_private.should == true
      task.update(is_private: false)
      task.is_private.should == true
    end

    it "should not remove the creator or assigned user from the watchers list" do
      user = FactoryBot.create(:user)
      project = FactoryBot.create(:project)
      project.add_user(user)

      task = FactoryBot.create(:task, is_private: true, project: project, user: project.user, assigned: project.people.last)

      current_watchers = task.watcher_ids.sort
      current_watchers.sort.should == [ project.user_id, user.id ].sort

      # assigned cannot be cleared
      task.comments.create_by_user task.user, { is_private: true, body: 'shouldclear', private_ids: [] }
      task.save
      Task.find_by_id(task.id).watcher_ids.sort.should == [ project.user_id, user.id ].sort

      Task.find_by_id(task.id).update(assigned_id: nil)
      task = Task.find_by_id(task.id)
      task.assigned.should == nil

      # unassigned user can now be cleared
      task.comments.create_by_user task.user, { is_private: true, body: 'shouldclear', private_ids: [] }
      task.save
      Task.find_by_id(task.id).watcher_ids.should == [ project.user_id ]
    end
  end

  xdescribe "google calendar system" do
    it "should create a correctly formatted GoogleCalendar::Event when sent #to_google_calendar_event" do
      task = FactoryBot.create(:task, due_on: Date.today)
      google_event = task.send(:to_google_calendar_event)
      google_event.title.should == "#{task.name} (#{task.project.name} - #{task.task_list.name})"
      google_event.details.strip.end_with?("/projects/#{task.project.to_param}/tasks/#{task.to_param}").should be true
      google_event.start.should == Date.today
      google_event.end.should == Date.today

      task.due_on.should be_instance_of(Date)
    end

    it "should create a correctly formatted GoogleCalendar::Event when sent #to_google_calendar_event with a body" do
      task = FactoryBot.create(:task, comments: [ FactoryBot.create(:comment, body: 'Do it by tomorrow') ])
      google_event = task.send(:to_google_calendar_event)
      google_event.title.should == "#{task.name} (#{task.project.name} - #{task.task_list.name})"
      google_event.details.start_with?("Do it by tomorrow").should be true
      google_event.details.end_with?("/projects/#{task.project.to_param}/tasks/#{task.to_param}").should be true
      google_event.start.should == task.due_on
      google_event.end.should == task.due_on
    end
  end
end
