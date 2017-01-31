require 'spec_helper'

describe Pushpad do
  describe "#auth_token=" do
    it "sets the Pushpad auth token globally" do
      Pushpad.auth_token = 'abc123'
      expect(Pushpad.auth_token).to eq 'abc123'
    end
  end

  describe "#project_id=" do
    it "sets the Pushpad project id globally" do
      Pushpad.project_id = 123
      expect(Pushpad.project_id).to eq 123
    end
  end

  describe "#signature_for" do
    it "produces the hex-encoded HMAC-SHA1 signature for the data passed as argument" do
      signature = Pushpad.signature_for('myuid1')
      expect(signature).to eq '27fbe136f5a4aa0b6be74c0e18fa8ce81ad91b60'
    end
  end
end
