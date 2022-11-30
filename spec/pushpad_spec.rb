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
    it "produces the hex-encoded HMAC-SHA256 signature for the data passed as argument" do
      signature = Pushpad.signature_for('myuid1')
      expect(signature).to eq 'd213a2f146dd9aae9cb935b5233d42fecc9414e2b0e98896af7a43e7fce3ef31'
    end
  end
end
