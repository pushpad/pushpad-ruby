require 'openssl'

require "pushpad/request"
require "pushpad/notification"
require "pushpad/subscription"

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

  def self.signature_for(data)
    raise "You must set Pushpad.auth_token" unless Pushpad.auth_token
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), self.auth_token, data.to_s)
  end

  def self.path(options = {})
    project_id = options[:project_id] || self.project_id
    raise "You must set project_id" unless project_id
    "https://pushpad.xyz/projects/#{self.project_id}/subscription/edit"
  end

  def self.path_for(user, options = {})
    uid = user.respond_to?(:id) ? user.id : user
    uid_signature = self.signature_for(uid.to_s)
    "#{self.path(options)}?uid=#{uid}&uid_signature=#{uid_signature}"
  end
end
