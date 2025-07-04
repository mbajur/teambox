require 'rails_helper'

describe Organization, type: :model do
  it { should have_many(:projects) }
  it { should have_many(:users) }
  it { should have_many(:task_list_templates) }

  # it { should validate_presence_of(:permalink) }
  it { should validate_length_of(:name).is_at_least(1) }
  it { should validate_length_of(:permalink).is_at_least(2) }

  describe "permalink" do
    it "should check weird permalinks" do
      %w[www help mail].each do |sym|
        FactoryBot.build(:organization, permalink: sym).should_not be_valid
      end

      %w[with_underscores with-dashes fuckingnormaldomain].each do |sym|
        FactoryBot.build(:organization, permalink: sym).should be_valid
      end
    end
  end

  describe "validating length of name and permalink" do
    it "should fail on create if the name is shorter than 1 chars" do
      organization = FactoryBot.build(:organization, name: "")
      organization.should be_invalid
      expect(organization.errors[:name].size).to eq(1)
    end

    it "should allow existent organizations to have a name at least 1 chars if they don't change it" do
      organization = FactoryBot.build(:organization, name: "a", permalink: "abcdefg")
      organization.save(validate: false)
      organization.should be_valid
    end

    it "should not allow permalinks with less than 4 chars" do
      organization = FactoryBot.build(:organization, name: "a", permalink: "abcdefg")
      organization.save(validate: false)
      organization.should be_valid
      organization.permalink = "2"
      organization.save
      (organization.reload.permalink.length >= 4).should == true
    end

    it "should fail if the name is updated and shorter than 1 chars" do
      organization = FactoryBot.create(:organization, name: "abc123")
      organization.name = ""
      organization.should be_invalid
    end
  end

  describe "domain" do
    it "should allow multiple organizations with nil domain" do
      FactoryBot.create(:organization, domain: nil)
      FactoryBot.build(:organization, domain: nil).should be_valid
    end
    it "should allow multiple organizations with blank domain" do
      FactoryBot.create(:organization, domain: '')
      FactoryBot.build(:organization, domain: '').should be_valid
    end
    it "shouldn't take a deleted organization's domain as busy" do
      o = FactoryBot.create(:organization, domain: 'mofo.teambox.dev')
      o.destroy
      FactoryBot.build(:organization, domain: 'mofo.teambox.dev').should be_valid
    end
  end

  it "should not be destroyed if it has any projects" do
    organization = FactoryBot.create(:organization)
    FactoryBot.create(:project, organization: organization)
    organization.reload.projects.count.should == 1
    expect { organization.destroy }.not_to change(Organization, :count)
  end

  describe "projects" do
    before do
      @organization = FactoryBot.create(:organization)
    end
    it "should add a project" do
      project = FactoryBot.create(:project, organization: @organization)
      project.valid?.should be true
      project.organization.should == @organization
    end
    it "should transfer projects" do
      project = FactoryBot.create(:project, organization: @organization)
      new_organization = FactoryBot.create(:organization)
      project.organization = new_organization
      project.save.should be true
      project.organization.should == new_organization
      @organization.projects.should == []
      new_organization.projects.should == [ project ]
    end
  end

  describe "users" do
    before do
      @organization = FactoryBot.create(:organization)
    end
    it "should add admins" do
      user = FactoryBot.create(:user)
      @organization.add_member(user, :admin)
      @organization.users.should == [ user ]
      @organization.admins.should == [ user ]
      @organization.participants.should == []
      @organization.external_users.should == []
      @organization.users_in_projects.should == []
      @organization.is_admin?(user).should be true
      @organization.is_participant?(user).should be false
    end
    it "should add participants" do
      user = FactoryBot.create(:user)
      @organization.add_member(user, :participant)
      @organization.users.should == [ user ]
      @organization.admins.should == []
      @organization.participants.should == [ user ]
      @organization.external_users.should == []
      @organization.users_in_projects.should == []
      @organization.is_admin?(user).should be false
      @organization.is_participant?(user).should be true
    end
    it "should list people in projects as external users" do
      project = FactoryBot.create(:project, organization: @organization)
      @organization.users.should == [ project.user ]
      @organization.admins.should == [ project.user ]
      @organization.participants.should == []
      @organization.external_users.should == []
      @organization.users_in_projects.should == [ project.user ]
      @organization.is_admin?(project.user).should be true
      @organization.is_participant?(project.user).should be false
    end
    it "should list people in projects and the org as users" do
      admin = FactoryBot.create(:user)
      @organization.add_member(admin, :admin)
      project = FactoryBot.create(:project, organization: @organization)
      @organization.add_member(project.user, :participant)
      @organization.reload.user_ids.sort.should == [ admin.id, project.user_id ].sort
      @organization.admins.should == [ admin ]
      @organization.participants.should == [ project.user ]
      @organization.external_users.should == []
      @organization.users_in_projects.should == [ project.user ]
      @organization.is_admin?(project.user).should be false
      @organization.is_participant?(project.user).should be true
    end

    it "should not add members with invalid roles" do
      user = FactoryBot.create(:user)
      @organization.add_member(user, 0).should be false
      @organization.add_member(user, 40).should be false
      @organization.add_member(-4).should be false
    end

    it "should not add members twice" do
      user = FactoryBot.create(:user)
      @organization.add_member(user, 20).should be true
      @organization.memberships.last.user_id.should == user.id
      @organization.memberships.length.should == 1
      @organization.add_member(user, 20)
      @organization.memberships.length.should == 1
    end

    it "should upgrade participants" do
      user = FactoryBot.create(:user)
      @organization.add_member(user, 10).should be true
      @organization.add_member(user, 30).should be true
      @organization.memberships.last.user_id.should == user.id
      @organization.memberships.last.role.should == 30
      @organization.memberships.length.should == 1
    end

    it "should not destroy or downgrade the last admin" do
      user = FactoryBot.create(:user)
      @organization.add_member(user, 30).should be true
      member = @organization.memberships.last
      member.role = 20
      member.save.should be false
    end

    it "should not destroy or downgrade the last admin" do
      user = FactoryBot.create(:user)
      @organization.add_member(user, 30).should be true
      member = @organization.memberships.last

      expect { member.destroy }.not_to change(Membership, :count)
    end

    xit "should destroy organization even if there is only one admin" do
      user = FactoryBot.create(:user)
      @organization.add_member(user, 30).should be true
      @organization.admins.count.should == 1

      expect { @organization.destroy! }.to change(Organization, :count).by(-1)
    end
  end

  describe "single organization mode" do
    before { Rails.configuration.teambox.community = true }
    after  { Rails.configuration.teambox.community = false }
    it "should allow creating one organization" do
      Organization.destroy_all
      FactoryBot.create(:organization).valid?.should be true
      FactoryBot.build(:organization).valid?.should be false
    end
  end

  describe "factories" do
    it "should generate a valid organization" do
      organization = FactoryBot.create(:organization)
      organization.valid?.should be true
      organization.users.should be_empty
      organization.projects.should be_empty
    end
  end

  # @todo remove paperclip
  xdescribe "logo" do
    before do
      Rails.configuration.teambox.amazon_s3 = false
      @organization = FactoryBot.create(:organization, logo: upload_file("#{Rails.root}/spec/fixtures/tb-space.jpg", 'image/jpeg'))
    end

    it "deletes the logo when delete_logo is set" do
      @organization.update_attributes delete_logo: '1'
      @organization.logo_file_name.should == nil
    end

    it "does not delete the logo when delete_logo is not set" do
      @organization.update_attributes delete_logo: '0'
      @organization.logo_file_name.should_not == nil
    end
  end
end
