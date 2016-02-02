module Rack
  module Delegate
    class Configuration < Struct.new(:actions)
      def self.from_block(&block)
        config = new
        config.instance_eval(&block)
        config.actions
      end

      def initialize
        @actions = []
        @constraints = []
        @rewriter = UriRewriter.new
        @changer = NetHttpRequestRewriter.new
      end

      def from(pattern, to:, constraints: nil)
        action = Action.new(pattern, Delegator.new(to, rewriter, changer))
        action = Rack::Timeout.new(action) if timeout?

        if constraints = Array(constraints).concat(@constraints) and !constraints.empty?
          action = ConstrainedAction.new(action, constraints)
        end

        actions << action
      end

      def rewrite(&block)
        @rewriter = UriRewriter.new do |uri|
          uri.instance_eval(&block)
          uri
        end
      end

      def change
        @changer = NetHttpRequestRewriter.new do |request|
          yield request
          request
        end
      end

      private

      attr_reader :rewriter, :changer

      def constraints(*args)
        @constraints << args.flatten
      end

      def timeout?
        require 'rack/timeout'
        true
      rescue LoadError
        false
      end
    end
  end
end
