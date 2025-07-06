require 'rails_helper'

describe ProjectsController, type: :controller do
  include AuthenticatedTestHelper

  render_views

  describe "#index" do
    before do
      @user = FactoryBot.create(:confirmed_user)
      @project = FactoryBot.create(:project)
      @project.add_user @user
    end

    xit "should show a project when using mobile views" do
      login_as @user

      get :index, params: { format: 'm' }

      response.should render_template('projects/index')
      response.body.match(/Use full Teambox/).should_not == nil
    end

    xit "should not shown private objects we cant see in feeds" do
      login_as @user

      conversation = FactoryBot.create(:conversation, project: @project, name: 'We screwed up', body: 'PANIC!', is_private: true)
      task = FactoryBot.create(:task, project: @project, name: 'Silence the critics', comments_attributes: { '0' => { 'body' => 'People are asking too many questions' } }, is_private: true)
      other_conversation = FactoryBot.create(:conversation, project: @project, name: 'We deny everything', body: 'Nothing wrong here')

      get :index, params: { format: 'rss' }
      response.body.match(/We screwed up/).should == nil
      response.body.match(/PANIC!/).should == nil
      response.body.match(/Silence the critics/).should == nil
      response.body.match(/People are asking too many questions/).should == nil
      response.body.match(/We deny everything/).should_not == nil
      response.body.match(/Nothing wrong here/).should_not == nil
    end

    xit "should not shown private objects we cant see in ical" do
      login_as @user

      task = FactoryBot.create(:task, project: @project, name: 'Silence the critics', comments_attributes: { '0' => { 'body' => 'People are asking too many questions' } }, is_private: true, due_on: Time.now)
      other_task = FactoryBot.create(:task, project: @project, name: 'Fix everything', due_on: Time.now)

      get :show, params: { id: @project.id, format: 'ics' }

      response.body.match(/Fix everything/).should_not == nil
      response.body.match(/Silence the critics/).should == nil
      response.body.match(/People are asking too many questions/).should == nil
    end
  end

  describe "#show" do
    before do
      @user = FactoryBot.create(:confirmed_user)
      @project = FactoryBot.create(:project)
      @project.add_user @user

      @task = FactoryBot.create(:task, project: @project, name: 'Silence the critics', comments_attributes: { '0' => { 'body' => 'People are asking too many questions' } }, is_private: true, due_on: Time.now)
    end

    xit "should not show private objects we cant see in feeds" do
      login_as @user

      conversation = FactoryBot.create(:conversation, project: @project, name: 'We screwed up', body: 'PANIC!', is_private: true)
      other_conversation = FactoryBot.create(:conversation, project: @project, name: 'We deny everything', body: 'Nothing wrong here')

      get :show, params: { id: @project.id, format: 'rss' }
      response.body.match(/We screwed up/).should == nil
      response.body.match(/PANIC!/).should == nil
      response.body.match(/Silence the critics/).should == nil
      response.body.match(/People are asking too many questions/).should == nil
      response.body.match(/We deny everything/).should_not == nil
      response.body.match(/Nothing wrong here/).should_not == nil
    end

    xit "should not show private objects we cant see in ical" do
      login_as @user

      other_task = FactoryBot.create(:task, project: @project, name: 'Fix everything', due_on: Time.now)

      get :show, params: { id: @project.id, format: 'ics' }

      response.body.match(/Fix everything/).should_not == nil
      response.body.match(/Silence the critics/).should == nil
      response.body.match(/People are asking too many questions/).should == nil
    end
  end

  describe "#create" do
    it "creates a project with invitations" do
      login_as(:confirmed_user)

      @user2 = FactoryBot.create(:user)

      project_attributes = FactoryBot.attributes_for(:project,
        organization_id: FactoryBot.create(:organization).id
      )

      invite_attributes = FactoryBot.attributes_for(:project,
        invite_users: [ @user2.id ],
        invite_emails: "richard.roe@law.uni"
      )

      lambda {
        post :create, params: { project: project_attributes }
        response.should be_redirect
      }.should change(Project, :count)
    end

    it "creates invitations for newly created project" do
      login_as(:confirmed_user)

      @user2 = FactoryBot.create(:user)

      project_attributes = FactoryBot.attributes_for(:project,
        organization_id: FactoryBot.create(:organization).id
      )

      invite_attributes = FactoryBot.attributes_for(:project,
        invite_users: [ @user2.id ],
        invite_emails: "richard.roe@law.uni"
      )

      post :create, params: { project: project_attributes }
      response.should be_redirect
      project = Project.order('id').last

      post :send_invites, params: { project_id: project.id, project: invite_attributes }
      response.should be_redirect
      project.invitations.with_deleted.count.should == 2
    end
  end

  describe "#create" do
    it "creates a project with an existing organization" do
      @user = FactoryBot.create(:confirmed_user)
      login_as @user

      @user2 = FactoryBot.create(:user)
      @org = FactoryBot.create(:organization)
      @org.add_member(@user, Membership::ROLES[:admin])

      project_attributes = FactoryBot.attributes_for(:project,
        organization_id: @org.id
      )

      invite_attributes = FactoryBot.attributes_for(:project,
        invite_users: [ @user2.id ],
        invite_emails: "richard.roe@law.uni"
      )

      lambda {
        post :create, params: { project: project_attributes }
        response.should be_redirect
      }.should change(Project, :count)

      project = Project.order('id').last

      post :send_invites, params: { project_id: project.id, project: invite_attributes }
      response.should be_redirect

      project.invitations.with_deleted.count.should == 2
    end
  end

  describe "#join" do
    it "should let admins from the projects organization add themselves" do
      @project = FactoryBot.create(:project)
      @user = FactoryBot.create(:confirmed_user)
      @project.organization.add_member(@user, Membership::ROLES[:admin])
      login_as @user

      lambda {
        get :join, params: { id: @project.permalink }
      }.should change(Person, :count)

      @project.people.map(&:user_id).include?(@project.user_id).should == true
    end

    it "should let people add themselves to public projects as commenters" do
      @project = FactoryBot.create(:project)
      @project.update_attribute(:public, true)
      @user = FactoryBot.create(:confirmed_user)
      login_as @user

      lambda {
        get :join, params: { id: @project.permalink }
      }.should change(Person, :count)

      @project.people.map(&:user_id).include?(@user.id).should == true
    end

    it "should not allow people to add themselves to non-public projects" do
      @project = FactoryBot.create(:project)
      @user = FactoryBot.create(:confirmed_user)

      login_as @user

      lambda {
        get :join, params: { id: @project.permalink }
      }.should_not change(Person, :count)

      @project.people.map(&:user_id).include?(@user.id).should == false
    end
  end
end
