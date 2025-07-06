require 'rails_helper'

describe OrganizationsController, type: :controller do
  include AuthenticatedTestHelper

  describe "#create" do
    it "creates an organization with the current user as an admin" do
      @user = FactoryBot.create(:confirmed_user)
      login_as @user

      organization_attributes = FactoryBot.attributes_for(:organization)

      lambda {
        post :create, params: { organization: organization_attributes }
        response.should be_redirect
      }.should change(Organization, :count)

      organization = Organization.order('id').last
      organization.memberships.count.should == 1
      organization.memberships.first.role.should == Membership::ROLES[:admin]
      organization.memberships.first.user.should == @user
    end
  end
end
