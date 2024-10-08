require "json"
require "time"

module Pushpad
  class Notification
    class DeliveryError < RuntimeError
    end

    class FindError < RuntimeError
    end
    
    class CancelError < RuntimeError
    end

    class ReadonlyError < RuntimeError
    end

    attr_accessor :body, :title, :target_url, :icon_url, :badge_url, :image_url, :ttl, :require_interaction, :silent, :urgent, :custom_data, :custom_metrics, :actions, :starred, :send_at
    attr_reader :id, :created_at, :scheduled_count, :successfully_sent_count, :opened_count

    def initialize(options)
      @id = options[:id]
      @created_at = options[:created_at] && Time.parse(options[:created_at])
      @scheduled_count = options[:scheduled_count]
      @successfully_sent_count = options[:successfully_sent_count]
      @opened_count = options[:opened_count]

      @body = options[:body]
      @title = options[:title]
      @target_url = options[:target_url]
      @icon_url = options[:icon_url]
      @badge_url = options[:badge_url]
      @image_url = options[:image_url]
      @ttl = options[:ttl]
      @require_interaction = options[:require_interaction]
      @silent = options[:silent]
      @urgent = options[:urgent]
      @custom_data = options[:custom_data]
      @custom_metrics = options[:custom_metrics]
      @actions = options[:actions]
      @starred = options[:starred]
      @send_at = options[:send_at]
    end

    def self.find(id)
      response = Request.get("https://pushpad.xyz/api/v1/notifications/#{id}")

      unless response.code == "200"
        raise FindError, "Response #{response.code} #{response.message}: #{response.body}"
      end

      new(JSON.parse(response.body, symbolize_names: true)).readonly!
    end

    def self.find_all(options = {})
      project_id = options[:project_id] || Pushpad.project_id
      raise "You must set project_id" unless project_id

      query_parameters = {}
      query_parameters[:page] = options[:page] if options.key?(:page)

      response = Request.get("https://pushpad.xyz/api/v1/projects/#{project_id}/notifications",
                             query_parameters: query_parameters)

      unless response.code == "200"
        raise FindError, "Response #{response.code} #{response.message}: #{response.body}"
      end

      JSON.parse(response.body, symbolize_names: true).map do |attributes|
        new(attributes).readonly!
      end
    end

    def readonly!
      @readonly = true
      self
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
    
    def cancel
      response = Request.delete("https://pushpad.xyz/api/v1/notifications/#{id}/cancel")

      unless response.code == "204"
        raise CancelError, "Response #{response.code} #{response.message}: #{response.body}"
      end
    end

    private

    def deliver(req_body, options = {})
      if @readonly
        raise(ReadonlyError,
              "Notifications fetched with `find` or `find_all` cannot be delivered again.")
      end

      project_id = options[:project_id] || Pushpad.project_id
      raise "You must set project_id" unless project_id

      endpoint = "https://pushpad.xyz/api/v1/projects/#{project_id}/notifications"
      response = Request.post(endpoint, req_body)

      unless response.code == "201"
        raise DeliveryError, "Response #{response.code} #{response.message}: #{response.body}"
      end

      JSON.parse(response.body).tap do |attributes|
        @id = attributes["id"]
        @scheduled_count = attributes["scheduled"]
      end
    end

    def req_body(uids = nil, tags = nil)
      notification_params = { "body" => self.body }
      notification_params["title"] = self.title if self.title
      notification_params["target_url"] = self.target_url if self.target_url
      notification_params["icon_url"] = self.icon_url if self.icon_url
      notification_params["badge_url"] = self.badge_url if self.badge_url
      notification_params["image_url"] = self.image_url if self.image_url
      notification_params["ttl"] = self.ttl if self.ttl
      notification_params["require_interaction"] = self.require_interaction unless self.require_interaction.nil?
      notification_params["silent"] = self.silent unless self.silent.nil?
      notification_params["urgent"] = self.urgent unless self.urgent.nil?
      notification_params["custom_data"] = self.custom_data if self.custom_data
      notification_params["custom_metrics"] = self.custom_metrics if self.custom_metrics
      notification_params["actions"] = self.actions if self.actions
      notification_params["starred"] = self.starred unless self.starred.nil?
      notification_params["send_at"] = self.send_at.utc.strftime("%Y-%m-%dT%R") if self.send_at

      body = { "notification" => notification_params }
      body["uids"] = uids if uids
      body["tags"] = tags if tags
      body.to_json
    end
  end
end
