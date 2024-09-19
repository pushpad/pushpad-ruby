require "spec_helper"

module Pushpad
  describe Subscription do
    def stub_subscription_get(options)
      stub_request(:get, "https://pushpad.xyz/api/v1/projects/#{options[:project_id]}/subscriptions/#{options[:id]}").
        to_return(status: 200, body: options[:attributes].to_json)
    end

    def stub_failing_subscription_get(options)
      stub_request(:get, "https://pushpad.xyz/api/v1/projects/#{options[:project_id]}/subscriptions/#{options[:id]}").
        to_return(status: 404)
    end
    
    def stub_subscriptions_head(options)
      stub_request(:head, "https://pushpad.xyz/api/v1/projects/#{options[:project_id]}/subscriptions").
        with(query: hash_including(options.fetch(:query, {}))).
        to_return(status: 200,
                  headers: { "X-Total-Count" => options.fetch(:total_count, 10) })
    end

    def stub_failing_subscriptions_head(options)
      stub_request(:head, "https://pushpad.xyz/api/v1/projects/#{options[:project_id]}/subscriptions").
        to_return(status: 503)
    end
    
    def stub_subscriptions_get(options)
      stub_request(:get, "https://pushpad.xyz/api/v1/projects/#{options[:project_id]}/subscriptions").
        with(query: hash_including(options.fetch(:query, {}))).
        to_return(status: 200, body: options[:list].to_json)
    end
    
    def stub_failing_subscriptions_get(options)
      stub_request(:get, "https://pushpad.xyz/api/v1/projects/#{options[:project_id]}/subscriptions").
        to_return(status: 403)
    end

    describe ".count" do
      it "returns value from X-Total-Count header" do
        stub_subscriptions_head(project_id: 5, total_count: 100)

        result = Subscription.count(project_id: 5)

        expect(result).to eq(100)
      end

      it "falls back to global project_id" do
        request = stub_subscriptions_head(project_id: 5, total_count: 100)

        Pushpad.project_id = 5
        Subscription.count

        expect(request).to have_been_made.once
      end

      it "fails with helpful error message when project_id is missing" do
        Pushpad.project_id = nil

        expect {
          Subscription.count
        }.to raise_error(/must set project_id/)
      end

      it "allows passing uids" do
        request = stub_subscriptions_head(project_id: 5, query: { uids:  ["uid0", "uid1"] })

        Subscription.count(project_id: 5, uids: ["uid0", "uid1"])

        expect(request).to have_been_made.once
      end

      it "allows passing tags" do
        request = stub_subscriptions_head(project_id: 5, query: { tags:  ["sports", "travel"] })

        Subscription.count(project_id: 5, tags: ["sports", "travel"])

        expect(request).to have_been_made.once
      end

      it "allows passing tags as boolean expression" do
        request = stub_subscriptions_head(project_id: 5, query: { tags: "sports || travel" })

        Subscription.count(project_id: 5, tags: "sports || travel")

        expect(request).to have_been_made.once
      end

      it "allows passing tags and uids" do
        request = stub_subscriptions_head(project_id: 5,
                                          query: { tags:  ["sports", "travel"], uids: ["uid0"] })

        Subscription.count(project_id: 5, tags: ["sports", "travel"], uids: ["uid0"])

        expect(request).to have_been_made.once
      end

      it "fails with CountError if response status code is not 200" do
        stub_failing_subscriptions_head(project_id: 5)

        expect {
          Subscription.count(project_id: 5)
        }.to raise_error(Subscription::CountError)
      end
    end
    
    describe ".find" do
      it "returns subscription with attributes from json response" do
        attributes = {
          id: 5,
          endpoint: "https://example.com/push/f7Q1Eyf7EyfAb1", 
          p256dh: "BCQVDTlYWdl05lal3lG5SKr3VxTrEWpZErbkxWrzknHrIKFwihDoZpc_2sH6Sh08h-CacUYI-H8gW4jH-uMYZQ4=",
          auth: "cdKMlhgVeSPzCXZ3V7FtgQ==",
          uid: "exampleUid", 
          tags: ["exampleTag1", "exampleTag2"],
          last_click_at: "2023-11-03T10:30:00.000Z",
          created_at: "2016-09-06T10:47:05.494Z"
        }
        stub_subscription_get(id: 5, project_id: 10, attributes: attributes)

        subscription = Subscription.find(5, project_id: 10)

        attributes.delete(:last_click_at)
        attributes.delete(:created_at)
        expect(subscription).to have_attributes(attributes)
        expect(subscription.last_click_at.utc.to_s).to eq(Time.utc(2023, 11, 3, 10, 30, 0.0).to_s)
        expect(subscription.created_at.utc.to_s).to eq(Time.utc(2016, 9, 6, 10, 47, 5.494).to_s)
      end

      it "fails with FindError if response status code is not 200" do
        stub_failing_subscription_get(id: 5, project_id: 10)

        expect {
          Subscription.find(5, project_id: 10)
        }.to raise_error(Subscription::FindError)
      end
      
      it "fails with helpful error message when project_id is missing" do
        Pushpad.project_id = nil

        expect {
          Subscription.find 5
        }.to raise_error(/must set project_id/)
      end
    end
    
    describe ".find_all" do
      it "returns subscriptions of project with attributes from json response" do
        attributes = {
          id: 1169,
          endpoint: "https://example.com/push/f7Q1Eyf7EyfAb1", 
          p256dh: "BCQVDTlYWdl05lal3lG5SKr3VxTrEWpZErbkxWrzknHrIKFwihDoZpc_2sH6Sh08h-CacUYI-H8gW4jH-uMYZQ4=",
          auth: "cdKMlhgVeSPzCXZ3V7FtgQ==",
          uid: "exampleUid", 
          tags: ["exampleTag1", "exampleTag2"],
          last_click_at: "2023-11-03T10:30:00.000Z",
          created_at: "2016-09-06T10:47:05.494Z"
        }
        stub_subscriptions_get(project_id: 10, list: [attributes])

        subscriptions = Subscription.find_all(project_id: 10)

        attributes.delete(:last_click_at)
        attributes.delete(:created_at)
        expect(subscriptions[0]).to have_attributes(attributes)
        expect(subscriptions[0].last_click_at.utc.to_s).to eq(Time.utc(2023, 11, 3, 10, 30, 0.0).to_s)
        expect(subscriptions[0].created_at.utc.to_s).to eq(Time.utc(2016, 9, 6, 10, 47, 5.494).to_s)
      end

      it "falls back to global project id" do
        attributes = { id: 5 }
        stub_subscriptions_get(project_id: 10, list: [attributes])

        Pushpad.project_id = 10
        subscriptions = Subscription.find_all

        expect(subscriptions[0]).to have_attributes(attributes)
      end

      it "fails with helpful error message when project_id is missing" do
        Pushpad.project_id = nil

        expect {
          Subscription.find_all
        }.to raise_error(/must set project_id/)
      end

      it "allows passing page parameter for pagination" do
        attributes = { id: 5 }
        stub_subscriptions_get(project_id: 10, list: [attributes], query: { page: "3" })

        subscriptions = Subscription.find_all(project_id: 10, page: 3)

        expect(subscriptions[0]).to have_attributes(attributes)
      end

      it "fails with FindError if response status code is not 200" do
        stub_failing_subscriptions_get(project_id: 10)

        expect {
          Subscription.find_all(project_id: 10)
        }.to raise_error(Subscription::FindError)
      end
      
      it "allows passing uids" do
        attributes = { id: 5 }
        request = stub_subscriptions_get(project_id: 5, list: [attributes], query: { uids:  ["uid0", "uid1"] })

        Subscription.find_all(project_id: 5, uids: ["uid0", "uid1"])

        expect(request).to have_been_made.once
      end

      it "allows passing tags" do
        attributes = { id: 5 }
        request = stub_subscriptions_get(project_id: 5, list: [attributes], query: { tags:  ["sports", "travel"] })

        Subscription.find_all(project_id: 5, tags: ["sports", "travel"])

        expect(request).to have_been_made.once
      end

      it "allows passing tags as boolean expression" do
        attributes = { id: 5 }
        request = stub_subscriptions_get(project_id: 5, list: [attributes], query: { tags: "sports || travel" })

        Subscription.find_all(project_id: 5, tags: "sports || travel")

        expect(request).to have_been_made.once
      end

      it "allows passing tags and uids" do
        attributes = { id: 5 }
        request = stub_subscriptions_get(project_id: 5, list: [attributes],
                                          query: { tags:  ["sports", "travel"], uids: ["uid0"] })

        Subscription.find_all(project_id: 5, tags: ["sports", "travel"], uids: ["uid0"])

        expect(request).to have_been_made.once
      end
      
      it "works properly when there are no results" do
        stub_subscriptions_get(project_id: 5, list: [])

        subscriptions = Subscription.find_all(project_id: 5)

        expect(subscriptions).to eq([])
      end
    end
    
  end
end
