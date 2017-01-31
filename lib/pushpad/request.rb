require "uri"
require "net/http"

module Pushpad
  module Request
    extend self

    def get(endpoint)
      uri = URI.parse(endpoint)
      request = Net::HTTP::Get.new(uri.path, headers)

      https(uri, request)
    end

    def post(endpoint, body)
      uri = URI.parse(endpoint)
      request = Net::HTTP::Post.new(uri.path, headers)
      request.body = body

      https(uri, request)
    end

    private

    def https(uri, request)
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |https|
        https.request(request)
      end
    end

    def headers
      raise "You must set Pushpad.auth_token" unless Pushpad.auth_token
      {
        "Authorization" => %(Token token="#{Pushpad.auth_token}"),
        "Content-Type" => "application/json;charset=UTF-8",
        "Accept" => "application/json"
      }
    end
  end
end
