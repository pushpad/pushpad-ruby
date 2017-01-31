require "spec_helper"

module Pushpad
  describe Notification do
    let!(:auth_token) { Pushpad.auth_token = "abc123" }
    let!(:project_id) { Pushpad.project_id = 123 }
    let(:notification) { Pushpad::Notification.new body: "Example message" }

    def stub_notification_post(project_id, params)
      stub_request(:post, "https://pushpad.xyz/projects/#{project_id}/notifications").
        with(body: hash_including(params)).
        to_return(status: 201, body: "{}")
    end

    describe "#deliver_to" do
      shared_examples "notification params" do
        it "includes the params in the request" do
          req = stub_notification_post project_id, notification: notification_params
          notification.deliver_to [123, 456]
          expect(req).to have_been_made.once
        end
      end

      context "a notification with just the required params" do
        let(:notification_params) do
          { body: "Example message" }
        end
        let(:notification) { Pushpad::Notification.new body: notification_params[:body] }
        include_examples "notification params"
      end

      context "a notification with all the optional params" do
        let(:notification_params) do
          {
            body: "Example message",
            title: "Website Name",
            target_url: "http://example.com",
            icon_url: "http://example.com/assets/icon.png",
            ttl: 604800,
            require_interaction: true
          }
        end
        let(:notification) { Pushpad::Notification.new notification_params }
        include_examples "notification params"
      end

      context "with a scalar as a param" do
        it "reaches only that uid" do
          req = stub_notification_post project_id, uids: [100]
          notification.deliver_to(100)
          expect(req).to have_been_made.once
        end
      end

      context "with an array as a param" do
        it "reaches only those uids" do
          req = stub_notification_post project_id, uids: [123, 456]
          notification.deliver_to([123, 456])
          expect(req).to have_been_made.once
        end
      end

      context "with uids and tags" do
        it "filters audience by uids and tags" do
          req = stub_notification_post project_id, uids: [123, 456], tags: ["tag1"]
          notification.deliver_to([123, 456], tags: ["tag1"])
          expect(req).to have_been_made.once
        end
      end
    end

    describe "#broadcast" do
      shared_examples "notification params" do
        it "includes the params in the request" do
          req = stub_notification_post project_id, notification: notification_params
          notification.broadcast
          expect(req).to have_been_made.once
        end
      end

      context "a notification with just the required params" do
        let(:notification_params) do
          { body: "Example message" }
        end
        let(:notification) { Pushpad::Notification.new body: notification_params[:body] }
        include_examples "notification params"
      end

      context "a notification with all the optional params" do
        let(:notification_params) do
          {
            body: "Example message",
            title: "Website Name",
            target_url: "http://example.com",
            icon_url: "http://example.com/assets/icon.png",
            ttl: 604800,
            require_interaction: true
          }
        end
        let(:notification) { Pushpad::Notification.new notification_params }
        include_examples "notification params"
      end

      context "without params" do
        it "reaches everyone" do
          req = stub_notification_post project_id, {}
          notification.broadcast
          expect(req).to have_been_made.once
        end
      end

      context "with tags" do
        it "filters audience by tags" do
          req = stub_notification_post project_id, tags: ["tag1", "tag2"]
          notification.broadcast tags: ["tag1", "tag2"]
          expect(req).to have_been_made.once
        end
      end
    end
  end
end
