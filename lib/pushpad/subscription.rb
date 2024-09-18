module Pushpad
  class Subscription
    class CountError < RuntimeError
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
