module Pushpad
  class Project
    class CreateError < RuntimeError
    end
    
    class FindError < RuntimeError
    end
    
    class UpdateError < RuntimeError
    end
    
    class DeleteError < RuntimeError
    end
    
    ATTRIBUTES = :id, :sender_id, :name, :website, :icon_url, :badge_url, :notifications_ttl, :notifications_require_interaction, :notifications_silent, :created_at
    
    attr_reader *ATTRIBUTES
    
    def initialize(options)
      @id = options[:id]
      @sender_id = options[:sender_id]
      @name = options[:name]
      @website = options[:website]
      @icon_url = options[:icon_url]
      @badge_url = options[:badge_url]
      @notifications_ttl = options[:notifications_ttl]
      @notifications_require_interaction = options[:notifications_require_interaction] 
      @notifications_silent = options[:notifications_silent]
      @created_at = options[:created_at] && Time.parse(options[:created_at])
    end
    
    def self.create(attributes)      
      endpoint = "https://pushpad.xyz/api/v1/projects"
      response = Request.post(endpoint, attributes.to_json)
      
      unless response.code == "201"
        raise CreateError, "Response #{response.code} #{response.message}: #{response.body}"
      end
      
      new(JSON.parse(response.body, symbolize_names: true))
    end
    
    def self.find(id)  
      response = Request.get("https://pushpad.xyz/api/v1/projects/#{id}")
      
      unless response.code == "200"
        raise FindError, "Response #{response.code} #{response.message}: #{response.body}"
      end
      
      new(JSON.parse(response.body, symbolize_names: true))
    end
    
    def self.find_all
      response = Request.get("https://pushpad.xyz/api/v1/projects")
      
      unless response.code == "200"
        raise FindError, "Response #{response.code} #{response.message}: #{response.body}"
      end
      
      JSON.parse(response.body, symbolize_names: true).map do |attributes|
        new(attributes)
      end
    end
    
    def update(attributes)      
      raise "You must set id" unless id
      
      endpoint = "https://pushpad.xyz/api/v1/projects/#{id}"
      response = Request.patch(endpoint, attributes.to_json)
      
      unless response.code == "200"
        raise UpdateError, "Response #{response.code} #{response.message}: #{response.body}"
      end
      
      updated = self.class.new(JSON.parse(response.body, symbolize_names: true))
      
      ATTRIBUTES.each do |attr|
        self.instance_variable_set("@#{attr}", updated.instance_variable_get("@#{attr}"))
      end
      
      self
    end
    
    def delete      
      raise "You must set id" unless id
      
      response = Request.delete("https://pushpad.xyz/api/v1/projects/#{id}")
      
      unless response.code == "202"
        raise DeleteError, "Response #{response.code} #{response.message}: #{response.body}"
      end
    end
    
  end
end
