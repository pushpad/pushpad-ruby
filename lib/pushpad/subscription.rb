module Pushpad
  class Subscription
    class CreateError < RuntimeError
    end
    
    class CountError < RuntimeError
    end
    
    class FindError < RuntimeError
    end
    
    attr_reader :id, :endpoint, :p256dh, :auth, :uid, :tags, :last_click_at, :created_at

    def initialize(options)
      @id = options[:id]
      @endpoint = options[:endpoint]
      @p256dh = options[:p256dh]
      @auth = options[:auth]
      @uid = options[:uid]
      @tags = options[:tags]
      @last_click_at = options[:last_click_at] && Time.parse(options[:last_click_at])
      @created_at = options[:created_at] && Time.parse(options[:created_at])
    end
    
    def self.create(attributes, options = {})
      project_id = options[:project_id] || Pushpad.project_id
      raise "You must set project_id" unless project_id
      
      endpoint = "https://pushpad.xyz/api/v1/projects/#{project_id}/subscriptions"
      response = Request.post(endpoint, attributes.to_json)

      unless response.code == "201"
        raise CreateError, "Response #{response.code} #{response.message}: #{response.body}"
      end
      
      new(JSON.parse(response.body, symbolize_names: true))
    end

    def self.count(options = {})
      project_id = options[:project_id] || Pushpad.project_id
      raise "You must set project_id" unless project_id

      endpoint = "https://pushpad.xyz/api/v1/projects/#{project_id}/subscriptions"
      response = Request.head(endpoint, query_parameters: query_parameters(options))

      unless response.code == "200"
        raise CountError, "Response #{response.code} #{response.message}: #{response.body}"
      end

      response["X-Total-Count"].to_i
    end
    
    def self.find(id, options = {})
      project_id = options[:project_id] || Pushpad.project_id
      raise "You must set project_id" unless project_id
      
      response = Request.get("https://pushpad.xyz/api/v1/projects/#{project_id}/subscriptions/#{id}")

      unless response.code == "200"
        raise FindError, "Response #{response.code} #{response.message}: #{response.body}"
      end

      new(JSON.parse(response.body, symbolize_names: true))
    end
    
    def self.find_all(options = {})
      project_id = options[:project_id] || Pushpad.project_id
      raise "You must set project_id" unless project_id

      query_parameters_with_pagination = query_parameters(options)
      query_parameters_with_pagination << ["page", options[:page]] if options.key?(:page)

      response = Request.get("https://pushpad.xyz/api/v1/projects/#{project_id}/subscriptions",
                             query_parameters: query_parameters_with_pagination)

      unless response.code == "200"
        raise FindError, "Response #{response.code} #{response.message}: #{response.body}"
      end

      JSON.parse(response.body, symbolize_names: true).map do |attributes|
        new(attributes)
      end
    end

    private

    def self.query_parameters(options)
      uids = options.fetch(:uids, [])
      uids_query = uids.map { |uid| ["uids[]", uid] }
      
      tags = options.fetch(:tags, [])
      tags_query = tags.is_a?(String) ? [["tags", tags]] : tags.map { |tag| ["tags[]", tag] }
      
      [uids_query, tags_query].flatten(1)
    end

  end
end
