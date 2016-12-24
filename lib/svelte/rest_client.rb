require 'faraday'
require 'faraday_middleware'
require 'typhoeus'
require 'typhoeus/adapters/faraday'

module Svelte
  # Rest client to make requests to the service endpoints
  class RestClient
    class << self

      # Makes an http call to a given REST endpoint
      # @param verb [String] http verb to use for the request
      #   (`get`, `post`, `put`, etc.)
      # @param url [String] request url
      # @param params [Hash] parameters to send to the request
      # @param options [Hash] options
      # @raise [HTTPError] if an HTTP layer error occurs,
      #   an exception will be raised
      #
      # @return [Faraday::Response] http response from the service
      def call(verb:, url:, consumes:, params: {}, options: {})
        connection(request_mimetype: consumes).send verb, url, params do |request|
          request.options.timeout = options[:timeout] if options[:timeout]
        end
      rescue Faraday::TimeoutError => e
        raise HTTPError.new(parent: e)
      rescue Faraday::ResourceNotFound => e
        raise HTTPError.new(parent: e)
      rescue Faraday::ClientError => e
        raise HTTPError.new(parent: e)
      end

      private

      def connection(request_mimetype:)
        @@connection ||= Faraday.new(ssl: { verify: true }) do |faraday|
          faraday.request request_type(request_mimetype)
          faraday.response :json, content_type: /\bjson$/
          faraday.adapter :typhoeus
        end
      end

      def request_type(mimetype)
        case mimetype
        when 'application/json'
          return :json
        when 'multipart/form-data', 'application/x-www-form-urlencoded'
          return :multipart
        end
      end
    end
  end
end
