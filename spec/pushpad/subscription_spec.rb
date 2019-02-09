require "spec_helper"

module Pushpad
  describe Subscription do
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
  end
end
