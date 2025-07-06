require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  include AuthenticatedTestHelper

  route_matches("/account/settings", :get, controller: "users", action: "edit", sub_action: 'settings')
  route_matches("/account/profile", :get, controller: "users", action: "edit", sub_action: 'profile')
  route_matches("/account/profile", :get, controller: "users", action: "edit", sub_action: 'profile')
  route_matches("/account/notifications", :get, controller: "users", action: "edit", sub_action: 'notifications')

  it 'allows signup' do
    expect {
      do_create
      expect(response).to redirect_to(root_path)
      # expect(flash[:success]).not_to be_blank
    }.to change(User, :count).by(1)
  end

  it 'requires email on signup' do
    expect {
      do_create(email: nil)
      expect(assigns(:user).errors[:email]).not_to be_empty
    }.not_to change(User, :count)
  end

  describe "on POST to create with bad params" do
    before do
      post :create, params: { user: { foo: 'bar' } }
    end

    it "should render the new template" do
      expect(response).to render_template('users/new')
    end

    it "should have errors on the user" do
      expect(assigns(:user)).not_to be_nil
    end

    it "should render the new user view" do
      expect(response).to render_template('users/new')
    end
  end

  describe "#show" do
    render_views

    before do
      @first_project = make_a_typical_project
      @first_user = @user
      @another_first_user = FactoryBot.create(:confirmed_user, first_name: 'Frank', last_name: 'Sinatra')
      @first_project.add_user(@another_first_user)

      @second_project = make_a_typical_project
      @second_user = @user
    end

    it "should not show unknown users" do
      login_as @first_user
      get :show, params: { id: @second_user.id }
      expect(response).not_to render_template('users/show')
      expect(response.status).to eq(302)
    end

    it "should show known users" do
      login_as @first_user
      get :show, params: { id: @first_project.user.id }
      expect(response).to render_template('users/show')
    end

    xit "should show the selected user in the title and not the logged in user" do
      login_as @first_user
      get :show, params: { id: @another_first_user.id }
      expect(response.body).to have_selector('title', text: @another_first_user.name)
      expect(response.body).not_to have_selector('title', text: @first_user.name)
    end

    xit "should show projects that you share with this user and not projects that you don't" do
      login_as @first_user
      get :show, params: { id: @another_first_user.id }
      expect(response.body).to have_selector('.project_link a', text: @first_project.name)
      expect(response.body).not_to have_selector('.project_link a', text: @second_project.name)
    end
  end

  def do_create(options = {})
    post :create, params: { user: {
      email: 'testing@localhost.com',
      login: 'testing',
      first_name: 'Andrew',
      last_name: 'Wiggin',
      password: 'testing',
      password_confirmation: 'testing'
    }.merge(options) }
  end
end
