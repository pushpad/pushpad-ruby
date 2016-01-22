require 'net/http'
require 'OpenSSL'
require 'json'

module Pushpad
  @@auth_token = nil
  @@project_id = nil

  def self.auth_token
    @@auth_token
  end

  def self.auth_token=(auth_token)
    @@auth_token = auth_token
  end

  def self.project_id
    @@project_id
  end

  def self.project_id=(project_id)
    @@project_id = project_id
  end

  def self.path(options = {})
    project_id = options[:project_id] || self.project_id
    raise "You must set project_id" unless project_id
    "https://pushpad.xyz/projects/#{self.project_id}/subscription/edit"
  end

  def self.path_for(user, options = {})
    raise "You must set Pushpad.auth_token" unless Pushpad.auth_token
    uid = user.respond_to?(:id) ? user.id : user
    uid_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), self.auth_token, uid.to_s)
    "#{self.path(options)}?uid=#{uid}&uid_signature=#{uid_signature}" 
  end

  class Notification
    class DeliveryError < RuntimeError
    end

    attr_accessor :body, :title, :target_url

    def initialize(options)
      self.body = options[:body]
      self.title = options[:title]
      self.target_url = options[:target_url]
    end

    def broadcast(options = {})
      deliver req_body, options
    end

    def deliver_to(users, options = {})
      uids = if users.respond_to?(:ids)
        users.ids
      elsif users.respond_to?(:collect)
        users.collect {|u| u.respond_to?(:id) ? u.id : u }
      else
        [users.respond_to?(:id) ? users.id : users]
      end
      deliver req_body(uids), options
    end

    private

    def deliver(req_body, options = {})
      project_id = options[:project_id] || Pushpad.project_id
      raise "You must set project_id" unless project_id
      endpoint = "https://pushpad.xyz/projects/#{project_id}/notifications"
      uri = URI.parse(endpoint)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      req = Net::HTTP::Post.new(uri.path, req_headers)
      req.body = req_body
      res = https.request(req)
      raise DeliveryError, "Response #{res.code} #{res.message}: #{res.body}" unless res.code == '201'
      JSON.parse(res.body)
    end

    def req_headers
      raise "You must set Pushpad.auth_token" unless Pushpad.auth_token
      {
        'Authorization' => 'Token token="' + Pushpad.auth_token + '"',
        'Content-Type' => 'application/json;charset=UTF-8',
        'Accept' => 'application/json'
      }
    end

    def req_body(uids = nil)
      body = {
        "notification" => {
          "body" => self.body,
          "title" => self.title,
          "target_url" => self.target_url
        }
      }
      body["uids"] = uids if uids
      body.to_json
    end
  end

end
