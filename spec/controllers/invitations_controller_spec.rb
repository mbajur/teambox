require 'rails_helper'

describe InvitationsController, type: :controller do
  include AuthenticatedTestHelper

  describe "#resend" do
    xit "resends an invite" do
      invitation = FactoryBot.create :invitation
      login_as invitation.user
      request.env['HTTP_REFERER'] = 'http://test.host/page'

      lambda {
        put :resend, params: { id: invitation.id, project_id: invitation.project.permalink }
        response.should redirect_to("http://test.host/projects/#{invitation.project.permalink}/people")
      }.should change(all_emails, :size)

      last_email_sent.should deliver_to(invitation.email)
    end
  end

  describe "#create" do
    before do
      @users = []
      @emails = "foo@localhost.com billg@microsoft.com fred@teambox.com"
      5.times { @users << FactoryBot.create(:user, auto_accept_invites: false) }
      @project = FactoryBot.create(:project)
    end

    it "accepts email addresses as email addresses" do
      login_as @project.user
      post :create, params: { project_id: @project.permalink, invitation: { user_or_email: @emails } }
      @project.invitations.length.should == 3
      @project.invitations.each { |invite| invite.invited_user.should == nil }
    end

    it "accepts usernames as existing users" do
      login_as @project.user
      post :create, params: { project_id: @project.permalink, invitation: { user_or_email: @users.map(&:login).join(' ') } }
      @project.invitations.length.should == 5
      @project.invitations.each { |invite| (@users.include?(invite.invited_user)).should == true }
    end

    it "accepts both emails and usernames" do
      login_as @project.user
      list = @users.map(&:login).join(' ') + ' ' + @emails
      post :create, params: { project_id: @project.permalink, invitation: { user_or_email: list } }
      @project.invitations.length.should == @users.count + 3
    end
  end
end
