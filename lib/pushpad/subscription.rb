module Pushpad
  class Subscription
    class CountError < RuntimeError
    end

    def self.count(options = {})
      CountQuery.new(options).perform
    end

    class CountQuery
      attr_reader :options

      def initialize(options)
        @options = options
      end

      def perform
        project_id = options[:project_id] || Pushpad.project_id
        raise "You must set project_id" unless project_id

        endpoint = "https://pushpad.xyz/projects/#{project_id}/subscriptions"
        response = Request.head(endpoint, query_parameters: query_parameters)

        unless response.code == "200"
          raise CountError, "Response #{response.code} #{response.message}: #{response.body}"
        end

        response["X-Total-Count"].to_i
      end

      private

      def query_parameters
        [uid_query_parameters, tag_query_parameters].flatten(1)
      end

      def uid_query_parameters
        options.fetch(:uids, []).map { |uid| ["uids[]", uid] }
      end

      def tag_query_parameters
        tags = options.fetch(:tags, [])

        if tags.is_a?(String)
          [["tags", tags]]
        else
          tags.map { |tag| ["tags[]", tag] }
        end
      end
    end
  end
end
