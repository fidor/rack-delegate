require 'rack'

module Rack
  module Delegate
    autoload :Rewriter, 'rack/delegate/rewriter'
    autoload :NetHttpRequestBuilder, 'rack/delegate/net_http_request_builder'
    autoload :Delegator, 'rack/delegate/delegator'
    autoload :NetworkErrorResponse, 'rack/delegate/network_error_response'
    autoload :Constraint, 'rack/delegate/constraint'
    autoload :Action, 'rack/delegate/action'
    autoload :ConstrainedAction, 'rack/delegate/constrained_action'
    autoload :Configuration, 'rack/delegate/configuration'
    autoload :Dispatcher, 'rack/delegate/dispatcher'

    class << self
      attr_accessor :network_error_response, :default_headers_callback
    end
    self.network_error_response = NetworkErrorResponse

    # Waits for an Array to be returned as part of the header used 
    # for delegating. Array needs to be [ [ HEADER_NAME, HEADER_VALUE]* ]
    def self.configure(&block)
      dispatcher = Dispatcher.configure(&block)

      Struct.new(:app) do
        define_method :call do |env|
          request = Request.new(env)

          if action = dispatcher.dispatch(request)
            action.call(env)
          else
            app.call(env)
          end
        end
      end
    end

    #
    # Will execute the Rack::Delegate.default_headers_callback if set.
    # This expects an hash to be returned to be used as default_headers
    # in the forwarded request. This method expects the request env as 
    # parameter
    def self.default_headers(env)
      Rack::Delegate.default_headers_callback && Rack::Delegate.default_headers_callback.call(env) || {}
    end
  end
end
