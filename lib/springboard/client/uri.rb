require 'uri'

module Springboard
  class Client
    ##
    # A wrapper around URI
    class URI
      ##
      # Returns a URI object based on the parsed string.
      #
      # @return [URI]
      def self.parse(value)
        return value.dup if value.is_a?(self)
        new(::URI.parse(value))
      end

      ##
      # Joins several URIs together.
      #
      # @return [URI]
      def self.join(*args)
        new(::URI.join(*args.map(&:to_s)))
      end

      ##
      # Creates a new URI object from an Addressable::URI
      #
      # @return [URI]
      def initialize(uri)
        @uri = uri
      end

      ##
      # Clones the URI object
      #
      # @return [URI]
      def dup
        self.class.new(@uri.dup)
      end

      ##
      # Returns a new URI with the given subpath appended to it. Ensures a single
      # forward slash between the URI's path and the given subpath.
      #
      # @return [URI]
      def subpath(subpath)
        uri = dup
        uri.path = "#{path}/" unless path.end_with?('/')
        self.class.join(uri, subpath.to_s.gsub(/^\//, ''))
      end

      ##
      # Merges the given hash of query string parameters and values with the URI's
      # existing query string parameters (if any).
      def merge_query_values!(values)
        self.query_values = (self.query_values || {}).merge(normalize_query_hash(values))
      end

      def ==(other_uri)
        return false unless other_uri.is_a?(self.class)
        uri == other_uri.__send__(:uri)
      end

      def query_values=(values)
        self.query = ::URI.encode_www_form(normalize_query_hash(values))
      end

      def query_values
        return nil if query.nil?
        Hash[::URI.decode_www_form(query)]
      end

      private

      attr_reader :uri

      def self.delegate_and_wrap(*methods)
        methods.each do |method|
          define_method(method) do |*args, &block|
            result = @uri.__send__(method, *args, &block)
            if result.is_a?(::URI)
              self.class.new(result)
            else
              result
            end
          end
        end
      end

      delegate_and_wrap(
        :join, :path, :path=, :form_encode, :to_s, :query, :query=
      )

      def normalize_query_hash(hash)
        hash.inject({}) do |copy, (k, v)|
          k = "#{k}[]" if v.is_a?(Array) && !k.end_with?('[]')
          copy[k.to_s] = case v
            when Hash then normalize_query_hash(v)
            when true, false then v.to_s
            else v end
          copy
        end
      end
    end
  end
end
