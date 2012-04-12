module Sagamore
  class Client
    class Response
      def initialize(response)
        @response = response
      end

      def [](key)
        body[key]
      end

      def raw_body
        @response.body
      end

      def body
        @data ||= Body.new JSON.parse(@response.body)
      end

      def success?
        status < 400
      end

      def method_missing(method, *args, &block)
        @response.respond_to?(method) ? @response.__send__(method, *args, &block) : super
      end
    end
  end
end

