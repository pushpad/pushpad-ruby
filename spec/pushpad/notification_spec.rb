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

    def stub_notifications_get(options)
      stub_request(:get, "https://pushpad.xyz/projects/#{options[:project_id]}/notifications").
        with(query: hash_including(options.fetch(:query, {}))).
        to_return(status: 200, body: options[:list].to_json)
    end

    def stub_failing_notifications_get(options)
      stub_request(:get, "https://pushpad.xyz/projects/#{options[:project_id]}/notifications").
        to_return(status: 403)
    end

    def stub_notification_post(project_id, params = {}, response_body = "{}")

      stub_request(:post, "https://pushpad.xyz/projects/#{project_id}/notifications").
        with(body: hash_including(params)).
        to_return(status: 201, body: response_body)
    end

    def stub_failing_notification_post(project_id)
      stub_request(:post, "https://pushpad.xyz/projects/#{project_id}/notifications").
        to_return(status: 403)
    end

    describe ".new" do
      it "allows delivering notifications even if an id attribute is supplied" do
        stub_notification_post(project_id)

        expect {
          Notification.new(id: "ignored").broadcast
        }.not_to raise_error
      end
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
          urgent: false,
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

      it "returns notification that fails with ReadonlyError when calling deliver_to" do
        stub_notification_get(id: 5)

        notification = Notification.find(5)

        expect {
          notification.deliver_to(100)
        }.to raise_error(Notification::ReadonlyError)
      end

      it "returns notification that fails with ReadonlyError when calling broadcast" do
        stub_notification_get(id: 5)

        notification = Notification.find(5)

        expect {
          notification.broadcast
        }.to raise_error(Notification::ReadonlyError)
      end
    end

    describe ".find_all" do
      it "returns notifications of project with attributes from json response" do
        attributes = {
          id: 5,
          title: "Foo Bar",
          body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
          target_url: "http://example.com",
          created_at: "2016-07-06T10:09:14.835Z",
          ttl: 604800,
          require_interaction: false,
          urgent: false,
          icon_url: "https://example.com/assets/icon.png",
          scheduled_count: 2,
          successfully_sent_count: 4,
          opened_count: 1
        }
        stub_notifications_get(project_id: 10, list: [attributes])

        notifications = Notification.find_all(project_id: 10)

        attributes.delete(:created_at)
        expect(notifications[0]).to have_attributes(attributes)
        expect(notifications[0].created_at.utc.to_s).to eq(Time.utc(2016, 7, 6, 10, 9, 14.835).to_s)
      end

      it "falls back to global project id" do
        attributes = { id: 5 }
        stub_notifications_get(project_id: 10, list: [attributes])

        Pushpad.project_id = 10
        notifications = Notification.find_all

        expect(notifications[0]).to have_attributes(attributes)
      end

      it "fails with helpful error message when project_id is missing" do
        Pushpad.project_id = nil

        expect {
          Notification.find_all
        }.to raise_error(/must set project_id/)
      end

      it "allows passing page parameter for pagination" do
        attributes = { id: 5 }
        stub_notifications_get(project_id: 10, list: [attributes], query: { page: "3" })

        notifications = Notification.find_all(project_id: 10, page: 3)

        expect(notifications[0]).to have_attributes(attributes)
      end

      it "fails with FindError if response status code is not 200" do
        stub_failing_notifications_get(project_id: 10)

        expect {
          Notification.find_all(project_id: 10)
        }.to raise_error(Notification::FindError)
      end

      it "returns notifications that fail with ReadonlyError when calling deliver_to" do
        stub_notifications_get(project_id: 10, list: [{ id: 5 }])

        notifications = Notification.find_all(project_id: 10)

        expect {
          notifications[0].deliver_to(100)
        }.to raise_error(Notification::ReadonlyError)
      end

      it "returns notifications that fail with ReadonlyError when calling broadcast" do
        stub_notifications_get(project_id: 10, list: [{ id: 5 }])

        notifications = Notification.find_all(project_id: 10)

        expect {
          notifications[0].broadcast
        }.to raise_error(Notification::ReadonlyError)
      end
    end

    shared_examples "delivery method" do |method|
      it "fails with DeliveryError if response status code is not 201" do
        stub_failing_notification_post(project_id)

        expect {
          method.call(notification)
        }.to raise_error(Notification::DeliveryError)
      end

      it "sets id and scheduled_count from json response" do
        response_body = {
          "id" => 3,
          "scheduled" => 5
        }.to_json
        stub_notification_post(project_id, {}, response_body)

        method.call(notification)

        expect(notification).to have_attributes(id: 3, scheduled_count: 5)
      end

      it "overrides id on subsequent calls" do
        id_counter = 0
        response_body = lambda do |*|
          id_counter += 1

          {
            "id" => id_counter,
            "scheduled" => 5
          }.to_json
        end
        stub_notification_post(project_id, {}, response_body)

        method.call(notification)
        method.call(notification)
        method.call(notification)

        expect(notification.id).to eq(3)
      end

      it "returns raw json response" do
        response = {
          "id" => 4,
          "scheduled" => 5,
          "uids" => ["uid0", "uid1"]
        }
        stub_notification_post(project_id, {}, response.to_json)

        result = method.call(notification)

        expect(result).to eq(response)
      end

      it "fails with helpful error message when project_id is missing" do
        Pushpad.project_id = nil

        expect {
          method.call(notification)
        }.to raise_error(/must set project_id/)
      end
    end

    describe "#deliver_to" do
      include_examples "delivery method", lambda { |notification|
        notification.deliver_to(100)
      }

      let(:notification_params_to_json) { {} }

      shared_examples "notification params" do
        it "includes the params in the request" do
          req = stub_notification_post project_id, notification: notification_params.merge(notification_params_to_json)
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
            image_url: "http://example.com/assets/image.png",
            ttl: 604800,
            require_interaction: true,
            urgent: true,
            custom_data: "123",
            custom_metrics: ["examples", "another_metric"],
            actions: [
              {
                title: "My Button 1",
                target_url: "http://example.com/button-link",
                icon: "http://example.com/assets/button-icon.png",
                action: "myActionName"
              }
            ],
            starred: true,
            send_at: Time.utc(2016, 7, 25, 10, 9)
          }
        end
        let(:notification_params_to_json) do
          {
            send_at: "2016-07-25T10:09"
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
      include_examples "delivery method", lambda { |notification|
        notification.broadcast
      }

      let(:notification_params_to_json) { {} }

      shared_examples "notification params" do
        it "includes the params in the request" do
          req = stub_notification_post project_id, notification: notification_params.merge(notification_params_to_json)
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
            image_url: "http://example.com/assets/image.png",
            ttl: 604800,
            require_interaction: true,
            urgent: true,
            custom_data: "123",
            custom_metrics: ["examples", "another_metric"],
            actions: [
              {
                title: "My Button 1",
                target_url: "http://example.com/button-link",
                icon: "http://example.com/assets/button-icon.png",
                action: "myActionName"
              }
            ],
            starred: true,
            send_at: Time.utc(2016, 7, 25, 10, 9)
          }
        end
        let(:notification_params_to_json) do
          {
            send_at: "2016-07-25T10:09"
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
