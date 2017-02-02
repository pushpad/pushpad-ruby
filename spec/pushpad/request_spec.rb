require "spec_helper"

module Pushpad
  describe Request do
    describe ".head" do
      it "passes auth_token in authorization header" do
        stub_request(:any, /pushpad.xyz/)

        Pushpad.auth_token = "abc123"
        Request.head("https://pushpad.xyz/example")

        expect(a_request(:head, "https://pushpad.xyz/example").
               with(headers: { "Authorization" => 'Token token="abc123"' })).to have_been_made
      end

      it "supports passing query parameters" do
        stub_request(:any, /pushpad.xyz/)

        Pushpad.auth_token = "abc123"
        Request.head("https://pushpad.xyz/example", query_parameters: [["some", "value"]])

        expect(a_request(:head, "https://pushpad.xyz/example?some=value")).to have_been_made
      end
    end

    describe ".get" do
      it "passes auth_token in authorization header" do
        stub_request(:any, /pushpad.xyz/)

        Pushpad.auth_token = "abc123"
        Request.get("https://pushpad.xyz/example")

        expect(a_request(:get, "https://pushpad.xyz/example").
               with(headers: { "Authorization" => 'Token token="abc123"' })).to have_been_made
      end

      it "supports passing query parameters" do
        stub_request(:any, /pushpad.xyz/)

        Pushpad.auth_token = "abc123"
        Request.get("https://pushpad.xyz/example", query_parameters: [["some", "value"]])

        expect(a_request(:get, "https://pushpad.xyz/example?some=value")).to have_been_made
      end
    end

    describe ".post" do
      it "passes auth_token in authorization header" do
        stub_request(:any, /pushpad.xyz/)

        Pushpad.auth_token = "abc123"
        Request.post("https://pushpad.xyz/example", '{"some": "value"}')

        expect(a_request(:post, "https://pushpad.xyz/example").
               with(headers: { "Authorization" => 'Token token="abc123"' })).to have_been_made
      end

      it "passes request body" do
        stub_request(:any, /pushpad.xyz/)

        Pushpad.auth_token = "abc123"
        Request.post("https://pushpad.xyz/example", '{"some": "value"}')

        expect(a_request(:post, "https://pushpad.xyz/example").
               with(body: '{"some": "value"}')).to have_been_made
      end

      it "supports passing query parameters" do
        stub_request(:any, /pushpad.xyz/)

        Pushpad.auth_token = "abc123"
        Request.post("https://pushpad.xyz/example", "{}", query_parameters: [["some", "value"]])

        expect(a_request(:post, "https://pushpad.xyz/example?some=value")).to have_been_made
      end
    end
  end
end
