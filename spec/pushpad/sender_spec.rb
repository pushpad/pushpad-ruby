require "spec_helper"

module Pushpad
  describe Sender do
    
    def stub_senders_post(attributes = {})
      stub_request(:post, "https://pushpad.xyz/api/v1/senders").
        with(body: hash_including(attributes)).
        to_return(status: 201, body: attributes.to_json)
    end
    
    def stub_failing_senders_post
      stub_request(:post, "https://pushpad.xyz/api/v1/senders").
        to_return(status: 422)
    end
    
    def stub_sender_get(attributes)
      stub_request(:get, "https://pushpad.xyz/api/v1/senders/#{attributes[:id]}").
        to_return(status: 200, body: attributes.to_json)
    end
    
    def stub_failing_sender_get(attributes)
      stub_request(:get, "https://pushpad.xyz/api/v1/senders/#{attributes[:id]}").
        to_return(status: 404)
    end
    
    def stub_senders_get(list)
      stub_request(:get, "https://pushpad.xyz/api/v1/senders").
        to_return(status: 200, body: list.to_json)
    end
    
    def stub_failing_senders_get
      stub_request(:get, "https://pushpad.xyz/api/v1/senders").
        to_return(status: 401)
    end
    
    def stub_sender_patch(id, attributes)
      stub_request(:patch, "https://pushpad.xyz/api/v1/senders/#{id}").
        with(body: hash_including(attributes)).
        to_return(status: 200, body: attributes.to_json)
    end
    
    def stub_failing_sender_patch(id)
      stub_request(:patch, "https://pushpad.xyz/api/v1/senders/#{id}").
        to_return(status: 422)
    end
    
    def stub_sender_delete(id)
      stub_request(:delete, "https://pushpad.xyz/api/v1/senders/#{id}").
        to_return(status: 204)
    end
    
    def stub_failing_sender_delete(id)
      stub_request(:delete, "https://pushpad.xyz/api/v1/senders/#{id}").
        to_return(status: 403)
    end
    
    describe ".create" do
      it "creates a new sender with the given attributes and returns it" do
        attributes = {
          name: "My sender"
        }
        stub = stub_senders_post(attributes)
        
        sender = Sender.create(attributes)
        expect(sender).to have_attributes(attributes)
        
        expect(stub).to have_been_requested
      end
      
      it "fails with CreateError if response status code is not 201" do
        attributes = { name: "" }
        stub_failing_senders_post
        
        expect {
          Sender.create(attributes)
        }.to raise_error(Sender::CreateError)
      end
    end
    
    describe ".find" do
      it "returns sender with attributes from json response" do
        attributes = {
          id: 182,
          name: "My sender",
          vapid_private_key: "-----BEGIN EC PRIVATE KEY----- ...",
          vapid_public_key: "-----BEGIN PUBLIC KEY----- ...",
          created_at: "2016-07-06T11:28:21.266Z"
        }
        stub_sender_get(attributes)
        
        sender = Sender.find(182)
        
        attributes.delete(:created_at)
        expect(sender).to have_attributes(attributes)
        expect(sender.created_at.utc.to_s).to eq(Time.utc(2016, 7, 6, 11, 28, 21.266).to_s)
      end

      it "fails with FindError if response status code is not 200" do
        attributes = { id: 362 }
        stub_failing_sender_get(attributes)
        
        expect {
          Sender.find(362)
        }.to raise_error(Sender::FindError)
      end
    end
    
    describe ".find_all" do
      it "returns senders with attributes from json response" do
        attributes = {
          id: 182,
          name: "My sender",
          vapid_private_key: "-----BEGIN EC PRIVATE KEY----- ...",
          vapid_public_key: "-----BEGIN PUBLIC KEY----- ...",
          created_at: "2016-07-06T11:28:21.266Z"
        }
        stub_senders_get([attributes])
        
        senders = Sender.find_all
        
        attributes.delete(:created_at)
        expect(senders[0]).to have_attributes(attributes)
        expect(senders[0].created_at.utc.to_s).to eq(Time.utc(2016, 7, 6, 11, 28, 21.266).to_s)
      end

      it "fails with FindError if response status code is not 200" do
        stub_failing_senders_get
        
        expect {
          Sender.find_all
        }.to raise_error(Sender::FindError)
      end

      it "works properly when there are no results" do
        stub_senders_get([])
        
        senders = Sender.find_all
        
        expect(senders).to eq([])
      end
    end
    
    describe "#update" do
      it "updates a sender with the given attributes and returns it" do
        attributes = {
          name: "The New Sender Name"
        }
        stub = stub_sender_patch(5, attributes)
        
        sender = Sender.new(id: 5)
        sender.update attributes
        expect(sender).to have_attributes(attributes)
        
        expect(stub).to have_been_requested
      end
      
      it "fails with UpdateError if response status code is not 200" do
        attributes = { name: "" }
        stub_failing_sender_patch(5)
        
        sender = Sender.new(id: 5)
        
        expect {
          sender.update attributes
        }.to raise_error(Sender::UpdateError)
      end
      
      it "fails with helpful error message when id is missing" do
        expect {
          Sender.new(id: nil).update({})
        }.to raise_error(/must set id/)
      end
    end
    
    describe "#delete" do
      it "deletes a sender" do
        stub = stub_sender_delete(5)
        
        sender = Sender.new(id: 5)
        res = sender.delete
        expect(res).to be_nil
        
        expect(stub).to have_been_requested
      end
      
      it "fails with DeleteError if response status code is not 204" do
        stub_failing_sender_delete(5)
        
        sender = Sender.new(id: 5)
        
        expect {
          sender.delete
        }.to raise_error(Sender::DeleteError)
      end
    end
    
  end
end
