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

end
