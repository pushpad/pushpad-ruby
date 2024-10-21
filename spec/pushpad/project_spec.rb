require "spec_helper"

module Pushpad
  describe Project do
    
    def stub_projects_post(attributes = {})
      stub_request(:post, "https://pushpad.xyz/api/v1/projects").
        with(body: hash_including(attributes)).
        to_return(status: 201, body: attributes.to_json)
    end
    
    def stub_failing_projects_post
      stub_request(:post, "https://pushpad.xyz/api/v1/projects").
        to_return(status: 422)
    end
    
    def stub_project_get(attributes)
      stub_request(:get, "https://pushpad.xyz/api/v1/projects/#{attributes[:id]}").
        to_return(status: 200, body: attributes.to_json)
    end
    
    def stub_failing_project_get(attributes)
      stub_request(:get, "https://pushpad.xyz/api/v1/projects/#{attributes[:id]}").
        to_return(status: 404)
    end
    
    def stub_projects_get(list)
      stub_request(:get, "https://pushpad.xyz/api/v1/projects").
        to_return(status: 200, body: list.to_json)
    end
    
    def stub_failing_projects_get
      stub_request(:get, "https://pushpad.xyz/api/v1/projects").
        to_return(status: 401)
    end
    
    def stub_project_patch(id, attributes)
      stub_request(:patch, "https://pushpad.xyz/api/v1/projects/#{id}").
        with(body: hash_including(attributes)).
        to_return(status: 200, body: attributes.to_json)
    end
    
    def stub_failing_project_patch(id)
      stub_request(:patch, "https://pushpad.xyz/api/v1/projects/#{id}").
        to_return(status: 422)
    end
    
    def stub_project_delete(id)
      stub_request(:delete, "https://pushpad.xyz/api/v1/projects/#{id}").
        to_return(status: 202)
    end
    
    def stub_failing_project_delete(id)
      stub_request(:delete, "https://pushpad.xyz/api/v1/projects/#{id}").
        to_return(status: 403)
    end
    
    describe ".create" do
      it "creates a new project with the given attributes and returns it" do
        attributes = {
          sender_id: 123,
          name: "My project",
          website: "https://example.com"
        }
        stub = stub_projects_post(attributes)
        
        project = Project.create(attributes)
        expect(project).to have_attributes(attributes)
        
        expect(stub).to have_been_requested
      end
      
      it "fails with CreateError if response status code is not 201" do
        attributes = { name: "My project" }
        stub_failing_projects_post
        
        expect {
          Project.create(attributes)
        }.to raise_error(Project::CreateError)
      end
    end
    
    describe ".find" do
      it "returns project with attributes from json response" do
        attributes = {
          id: 361,
          sender_id: 123,
          name: "Example Project",
          website: "https://example.com",
          icon_url: "https://example.com/icon.png",
          badge_url: "https://example.com/badge.png",
          notifications_ttl: 604800,
          notifications_require_interaction: false,
          notifications_silent: false,
          created_at: "2016-07-06T10:58:39.143Z"
        }
        stub_project_get(attributes)
        
        project = Project.find(361)
        
        attributes.delete(:created_at)
        expect(project).to have_attributes(attributes)
        expect(project.created_at.utc.to_s).to eq(Time.utc(2016, 7, 6, 10, 58, 39.143).to_s)
      end

      it "fails with FindError if response status code is not 200" do
        attributes = { id: 362 }
        stub_failing_project_get(attributes)
        
        expect {
          Project.find(362)
        }.to raise_error(Project::FindError)
      end
    end
    
    describe ".find_all" do
      it "returns projects with attributes from json response" do
        attributes = {
          id: 361,
          sender_id: 123,
          name: "Example Project",
          website: "https://example.com",
          icon_url: "https://example.com/icon.png",
          badge_url: "https://example.com/badge.png",
          notifications_ttl: 604800,
          notifications_require_interaction: false,
          notifications_silent: false,
          created_at: "2016-07-06T10:58:39.143Z"
        }
        stub_projects_get([attributes])
        
        projects = Project.find_all
        
        attributes.delete(:created_at)
        expect(projects[0]).to have_attributes(attributes)
        expect(projects[0].created_at.utc.to_s).to eq(Time.utc(2016, 7, 6, 10, 58, 39.143).to_s)
      end

      it "fails with FindError if response status code is not 200" do
        stub_failing_projects_get
        
        expect {
          Project.find_all
        }.to raise_error(Project::FindError)
      end

      it "works properly when there are no results" do
        stub_projects_get([])
        
        projects = Project.find_all
        
        expect(projects).to eq([])
      end
    end
    
    describe "#update" do
      it "updates a project with the given attributes and returns it" do
        attributes = {
          name: "The New Project Name"
        }
        stub = stub_project_patch(5, attributes)
        
        project = Project.new(id: 5)
        project.update attributes
        expect(project).to have_attributes(attributes)
        
        expect(stub).to have_been_requested
      end
      
      it "fails with UpdateError if response status code is not 200" do
        attributes = { name: "" }
        stub_failing_project_patch(5)
        
        project = Project.new(id: 5)
        
        expect {
          project.update attributes
        }.to raise_error(Project::UpdateError)
      end
      
      it "fails with helpful error message when id is missing" do
        expect {
          Project.new(id: nil).update({})
        }.to raise_error(/must set id/)
      end
    end
    
    describe "#delete" do
      it "deletes a project" do
        stub = stub_project_delete(5)
        
        project = Project.new(id: 5)
        res = project.delete
        expect(res).to be_nil
        
        expect(stub).to have_been_requested
      end
      
      it "fails with DeleteError if response status code is not 202" do
        stub_failing_project_delete(5)
        
        project = Project.new(id: 5)
        
        expect {
          project.delete
        }.to raise_error(Project::DeleteError)
      end
    end
    
  end
end
