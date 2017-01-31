require "json"
require "time"

module Pushpad
  class Notification
    class DeliveryError < RuntimeError
    end

    class FindError < RuntimeError
    end

    class ReadOnlyError < RuntimeError
    end

    attr_accessor :body, :title, :target_url, :icon_url, :ttl, :require_interaction
    attr_reader :id, :created_at, :scheduled_count, :successfully_sent_count, :opened_count

    def initialize(options)
      @id = options[:id]
      @read_only = options.key?(:id)

      @created_at = options[:created_at] && Time.parse(options[:created_at])
      @scheduled_count = options[:scheduled_count]
      @successfully_sent_count = options[:successfully_sent_count]
      @opened_count = options[:opened_count]

      @body = options[:body]
      @title = options[:title]
      @target_url = options[:target_url]
      @icon_url = options[:icon_url]
      @ttl = options[:ttl]
      @require_interaction = options[:require_interaction]
    end

    def self.find(id)
      response = Request.get("https://pushpad.xyz/notifications/#{id}")

      unless response.code == "200"
        raise FindError, "Response #{response.code} #{response.message}: #{response.body}"
      end

      new(JSON.parse(response.body, symbolize_names: true))
    end

    def broadcast(options = {})
      deliver req_body(nil, options[:tags]), options
    end

    def deliver_to(users, options = {})
      uids = if users.respond_to?(:ids)
        users.ids
      elsif users.respond_to?(:collect)
        users.collect {|u| u.respond_to?(:id) ? u.id : u }
      else
        [users.respond_to?(:id) ? users.id : users]
      end
      deliver req_body(uids, options[:tags]), options
    end

    private

    def deliver(req_body, options = {})
      if @read_only
        raise ReadOnlyError, "Notifications fetched with `find` cannot be delivered again."
      end

      project_id = options[:project_id] || Pushpad.project_id
      raise "You must set project_id" unless project_id

      endpoint = "https://pushpad.xyz/projects/#{project_id}/notifications"
      response = Request.post(endpoint, req_body)

      unless response.code == "201"
        raise DeliveryError, "Response #{response.code} #{response.message}: #{response.body}"
      end

      JSON.parse(response.body)
    end

    def req_body(uids = nil, tags = nil)
      notification_params = { "body" => self.body }
      notification_params["title"] = self.title if self.title
      notification_params["target_url"] = self.target_url if self.target_url
      notification_params["icon_url"] = self.icon_url if self.icon_url
      notification_params["ttl"] = self.ttl if self.ttl
      notification_params["require_interaction"] = self.require_interaction unless self.require_interaction.nil?

      body = { "notification" => notification_params }
      body["uids"] = uids if uids
      body["tags"] = tags if tags
      body.to_json
    end
  end
end
