require 'rspec'
require 'rails_helper'

RSpec.describe 'Resource model methods functionality', :type => :model do
  describe 'create resource functionality' do
    it 'creates resources in the database' do
      Resource.destroy_all
      Resource.create_resource "title" => "thing1", "url" => "something.com", "contact_email" => "something@gmail.com", "location" => "someplace",
                               "types" => 'Scholarship,Funding,Events,Networking', "audiences" => 'Grad,Undergrad', "description" => "descriptions"
      Resource.create_resource "title" => "thing2", "url" => "something.com", "contact_email" => "something@gmail.com", "location" => "someplace",
                               "types" => 'Scholarship,Funding,Mentoring', "audiences" => 'Grad,Undergrad', "description" => "descriptions"
      result = Resource.all.order(:title)
      expect(result.count).to eq 2
      expect(result.first.title).to eq "thing1"
      expect(result.second.title).to eq "thing2"
    end
  end

  describe 'filter functionality' do
    before(:each) do
      Resource.destroy_all
      @resource1 = Resource.create_resource "title" => "thing1", "url" => "something.com", "contact_email" => "something@gmail.com", "location" => "Global",
                                            "types" => 'Scholarship,Funding,Events,Networking', "audiences" => 'Grad,Undergrad', "description" => "descriptions", "approval_status" => 0

      @resource2 = Resource.create_resource "title" => "thing2", "url" => "something.com", "contact_email" => "something@gmail.com", "location" => "Global",
                                            "types" => 'Scholarship,Funding,Events,Networking', "audiences" => 'Grad,Undergrad', "description" => "descriptions", "approval_status" => 0

      @resource3 = Resource.create_resource "title" => "thing3", "url" => "something.com", "contact_email" => "something@gmail.com", "location" => "Global",
                                            "types" => 'Scholarship,Events,Networking', "audiences" => 'Grad,Undergrad', "description" => "descriptions", "approval_status" => 0

      @resource4 = Resource.create_resource "title" => "thing4", "url" => "something.com", "contact_email" => "something@gmail.com", "location" => "someplace",
                               "types" => 'Funding,Mentoring', "audiences" => 'Grad,Undergrad', "description" => "descriptions"

      User.delete_all
      User.create!(:email => 'example@gmail.com', :password => 'password', :api_token => 'example')
    end

    it 'can do a simple filter by column name' do
      result = Resource.filter({"title" => "thing3"})
      # print result.pretty_print_inspect
      expect(result.count).to eq 1
      expect(result.first.title).to eq "thing3"
    end

    it 'returns the flagged resources if flagged is specified' do
      Resource.create_resource "title" => "thing5", "url" => "something.com", "contact_email" => "something@gmail.com", "location" => "someplace",
                               "types" => 'Funding,Mentoring', "audiences" => 'Grad,Undergrad', "description" => "descriptions", "flagged" => 1
      result = Resource.filter({"flagged" => 1})
      # print result.pretty_print_inspect
      expect(result.count).to eq 1
      expect(result.first.title).to eq "thing5"
    end

    it 'splits has_many associations correctly and returns the right thing' do
      result = Resource.filter({:types=>"Scholarship,Funding"})
      # print result.pretty_print_inspect
      expect(result.count).to eq 2
      expect(result.where(title: "thing1")).to exist
      expect(result.where(title: "thing2")).to exist
      expect(result.where(title: "thing3")).not_to exist
      expect(result.where(title: "thing4")).not_to exist
    end

    it 'returns all resources if no filter is specified' do
      result = Resource.filter({})
      # print result.pretty_print_inspect
      expect(result.count).to eq 4
      expect(result.where(title: "thing1")).to exist
      expect(result.where(title: "thing2")).to exist
      expect(result.where(title: "thing3")).to exist
      expect(result.where(title: "thing4")).to exist
    end
  end

  describe 'location functionality' do
    before(:each) do
      Resource.destroy_all
      @resource1 = Resource.create_resource "title" => "thing1", "url" => "something.com", "contact_email" => "something@gmail.com", "location" => "Global",
                                            "types" => 'Scholarship,Funding,Events,Networking', "audiences" => 'Grad,Undergrad', "description" => "descriptions", "approval_status" => 0

      @resource2 = Resource.create_resource "title" => "thing2", "url" => "something.com", "contact_email" => "something@gmail.com", "location" => "Berkeley",
                                            "types" => 'Scholarship,Funding,Mentoring', "audiences" => 'Grad,Undergrad', "description" => "descriptions", "approval_status" => 0

      @resource3 = Resource.create_resource "title" => "thing3", "url" => "something.com", "contact_email" => "something@gmail.com", "location" => "USA",
                                            "types" => 'Scholarship,Funding,Events,Networking', "audiences" => 'Grad,Undergrad', "description" => "descriptions", "approval_status" => 0

      @resource4 = Resource.create_resource "title" => "thing4", "url" => "something.com", "contact_email" => "something@gmail.com", "location" => "California",
                                            "types" => 'Funding,Mentoring', "audiences" => 'Grad,Undergrad', "description" => "descriptions"

      @resource5 = Resource.create_resource "title" => "thing5", "url" => "something.com", "contact_email" => "something@gmail.com", "location" => "Seattle",
                                            "types" => 'Funding,Mentoring', "audiences" => 'Grad,Undergrad', "description" => "descriptions"

      User.delete_all
      User.create!(:email => 'example@gmail.com', :password => 'password', :api_token => 'example')

      Location.delete_all
      Location.seed
      Location.nest_location("Global")
      Location.nest_location("Berkeley")
      Location.nest_location("USA")
      Location.nest_location("California")
      Location.nest_location("Seattle")
    end


    it 'gets child locations' do
      result = Resource.location_helper({:location => "California"})

      expect(result.count).to eq 2
      expect(result.where(title: "thing2")).to exist
      expect(result.where(title: "thing4")).to exist
    end

    it 'returns no results given an invalid location' do
      result = Resource.location_helper({:location => "fake location"})
      expect(result.count).to eq 0
    end

    it 'does not null pointer given location with no children' do
      result = Resource.location_helper({:location => "Berkeley"})
      expect(result.count).to eq 1
      expect(result.where(title: "thing2")).to exist
    end

    it 'does not null pointer given global' do
      result = Resource.location_helper({:location => "Global"})
      expect(result.count).to eq 5
      expect(result.where(title: "thing1")).to exist
      expect(result.where(title: "thing2")).to exist
      expect(result.where(title: "thing3")).to exist
      expect(result.where(title: "thing4")).to exist
      expect(result.where(title: "thing5")).to exist
    end

    # removed this functionality
    # it 'finds children for a location not explicitly added to the database' do
    #   result = Resource.location_helper({:location => "Washington"})
    #   expect(result.count).to eq 1
    #   expect(result.where(title: "thing5")).to exist
    # end

    it 'allows for the adding of new locations' do
      Location.nest_location("Hawaii")
      result = Resource.location_helper({:location => "Global"})
      expect(result.count).to eq 5
      expect(result.where(title: "thing1")).to exist
      expect(result.where(title: "thing2")).to exist
      expect(result.where(title: "thing3")).to exist
      expect(result.where(title: "thing4")).to exist
      expect(result.where(title: "thing5")).to exist
    end

    it 'finds all of the child locations' do
      # assumes seeded data has locations that include:
      # California, Bay Area, Berkeley, UC Berkeley
      result = Location.child_locations("California")
      expect(result.count).to eq 4
    end

    it 'successfully manually adds a single location' do
      Location.add_location("foo", "Global")
      result = Location.child_locations("foo")
      expect(result.count).to eq 1
    end
  end

  # Testing for Broken URL
  describe 'RSpec Tests for Broken URL flag' do
    fixtures :resources
    before(:each) do
      Resource.destroy_all
      @resource_flaggedTypeBrokenURL = Resource.create_resource "title" => "thing1", "url" => "something.com", "contact_email" => "something@gmail.com", "location" => "Global",
                                                                "types" => 'BrokenURL, Scholarship,Funding,Events,Networking', "audiences" => 'Grad,Undergrad', "description" => "descriptions", "approval_status" => 0

      @resource_badURLNotTaggedYet = Resource.create_resource "title" => "thing2", "url" => "BADURL", "contact_email" => "something@gmail.com", "location" => "Global",
                                                              "types" => 'Scholarship,Funding,Events,Networking', "audiences" => 'Grad,Undergrad', "description" => "descriptions", "approval_status" => 0


      @resource3 = Resource.create_resource "title" => "thing3", "url" => "www.google.com", "contact_email" => "something@gmail.com", "location" => "Global",
                                            "types" => 'Scholarship,Events,Networking', "audiences" => 'Grad,Undergrad', "description" => "descriptions", "approval_status" => 0

      @resource4 = Resource.create_resource "title" => "thing4", "url" => "www.facebook.com", "contact_email" => "something@gmail.com", "location" => "someplace",
                                            "types" => 'Funding,Mentoring', "audiences" => 'Grad,Undergrad', "description" => "descriptions"

      User.delete_all
      User.create!(:email => 'example@gmail.com', :password => 'password', :api_token => 'example')
    end

    it 'should send an email to resource owners who own resources with
        bad URLs' do
      expect { Resource.first.isURLBroken_ifSoTagIt }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

  end

  describe 'approval_emails' do
    fixtures :resources
    it 'should send a reminder email to resources (with a valid resource owner
        email) who has been approved has passed' do
      expect { Resource.approval_email(Resource.first) }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'should not change updated_at attribute' do
      expect { Resource.approval_email(Resource.first) }.to_not change { Resource.first.updated_at }
    end

    it 'should update approval_num to be 1 and approval_last to the current time' do
      frozen_time = Time.local(2019, 11, 11)
      Timecop.freeze(frozen_time)
      Resource.approval_email(Resource.first)
      expect(Resource.first.approval_num).to eq 1
      expect(Resource.first.approval_last).to eq frozen_time
    end
  end

  describe 'broken_url_emails' do
    fixtures :resources

    it 'should send a reminder email to the resource owner' do
      expect { Resource.broken_url_email(Resource.first) }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'should not change updated_at attribute' do
      expect { Resource.broken_url_email(Resource.first) }.to_not change { Resource.first.updated_at }
    end

    it 'should update broken_num to be 1 and broken_last to the current time' do
      frozen_time = Time.local(2019, 11, 11)
      Timecop.freeze(frozen_time)
      Resource.broken_url_email(Resource.first)
      expect(Resource.first.broken_num).to eq 1
      expect(Resource.first.broken_last).to eq frozen_time
    end
  end

end