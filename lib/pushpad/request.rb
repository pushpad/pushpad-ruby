require "uri"
require "net/http"

module Pushpad
  module Request
    extend self

    def head(endpoint, options = {})
      perform(Net::HTTP::Head, endpoint, options)
    end

    def get(endpoint, options = {})
      perform(Net::HTTP::Get, endpoint, options)
    end

    def post(endpoint, body, options = {})
      perform(Net::HTTP::Post, endpoint, options) do |request|
        request.body = body
      end
    end
    
    def patch(endpoint, body, options = {})
      perform(Net::HTTP::Patch, endpoint, options) do |request|
        request.body = body
      end
    end
    
    def delete(endpoint, options = {})
      perform(Net::HTTP::Delete, endpoint, options)
    end

    private

    def perform(method, endpoint, options)
      uri = URI.parse(endpoint)
      request = method.new(path_and_query(uri, options[:query_parameters]), headers)

      yield request if block_given?

      https(uri, request)
    end

    def path_and_query(uri, query_parameters)
      [uri.path, query(query_parameters)].compact.join("?")
    end

    def query(parameters)
      parameters && !parameters.empty? ? URI.encode_www_form(parameters) : nil
    end

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
