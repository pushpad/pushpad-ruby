require "spec_helper"

module Pushpad
  describe Notification do
    let!(:auth_token) { Pushpad.auth_token = "abc123" }
    let!(:project_id) { Pushpad.project_id = 123 }
    let(:notification) { Pushpad::Notification.new body: "Example message" }

    def stub_notification_get(attributes)
      stub_request(:get, "https://pushpad.xyz/notifications/#{attributes[:id]}").
        to_return(status: 200, body: attributes.to_json)
    end

    def stub_failing_notification_get(notification_id)
      stub_request(:get, "https://pushpad.xyz/notifications/#{notification_id}").
        to_return(status: 404)
    end

    def stub_notification_post(project_id, params)
      stub_request(:post, "https://pushpad.xyz/projects/#{project_id}/notifications").
        with(body: hash_including(params)).
        to_return(status: 201, body: "{}")
    end

    def stub_failing_notification_post(project_id)
      stub_request(:post, "https://pushpad.xyz/projects/#{project_id}/notifications").
        to_return(status: 403)
    end

    describe ".find" do
      it "returns notification with attributes from json response" do
        attributes = {
          id: 5,
          title: "Foo Bar",
          body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
          target_url: "http://example.com",
          created_at: "2016-07-06T10:09:14.835Z",
          ttl: 604800,
          require_interaction: false,
          icon_url: "https://example.com/assets/icon.png",
          scheduled_count: 2,
          successfully_sent_count: 4,
          opened_count: 1
        }
        stub_notification_get(attributes)

        notification = Notification.find(5)

        attributes.delete(:created_at)
        expect(notification).to have_attributes(attributes)
        expect(notification.created_at.utc.to_s).to eq(Time.utc(2016, 7, 6, 10, 9, 14.835).to_s)
      end

      it "fails with FindError if response status code is not 200" do
        stub_failing_notification_get(5)

        expect {
          Notification.find(5)
        }.to raise_error(Notification::FindError)
      end

      it "returns notification that fails with ReadOnlyError when calling deliver_to" do
        stub_notification_get(id: 5)

        notification = Notification.find(5)

        expect {
          notification.deliver_to(100)
        }.to raise_error(Notification::ReadOnlyError)
      end

      it "returns notification that fails with ReadOnlyError when calling broadcast" do
        stub_notification_get(id: 5)

        notification = Notification.find(5)

        expect {
          notification.broadcast
        }.to raise_error(Notification::ReadOnlyError)
      end
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

      it "fails with DeliveryError if response status code is not 201" do
        stub_failing_notification_post(project_id)

        expect {
          notification.deliver_to(100)
        }.to raise_error(Notification::DeliveryError)
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

      it "fails with DeliveryError if response status code is not 201" do
        stub_failing_notification_post(project_id)

        expect {
          notification.broadcast
        }.to raise_error(Notification::DeliveryError)
      end
    end
  end
end
