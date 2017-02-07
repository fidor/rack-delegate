require 'test_helper'

module Rack
  module Delegate
    class NetHttpRequestBuilderTest < Minitest::Test
      @@env = Rack::MockRequest.env_for('http://example.com/prefix/foo/42',
        'REQUEST_METHOD' => 'POST',
        'REMOTE_ADDR' => '123.123.123.123',
        'HTTP_X_CUSTOM_HEADER' => '42',
        'HTTP_HOST' => 'example.com',
        'HTTP_CONNECTION' => 'Keep-Alive',
        'CONTENT_TYPE' => 'application/json',
        'CONTENT_LENGTH' => '2',
        'rack.input' => StringIO.new('42'),
        'action_dispatch.request_id' => '42'
      )

      @@request = Rack::Request.new(@@env)
      @@uri_rewriter = Rewriter.new { |u| u.path = u.path.gsub('/prefix', ''); u }
      @@request_rewriter = Rewriter.new

      test "delegates all the Rack request headers" do
        assert_equal @@env['HTTP_X_CUSTOM_HEADER'], net_http_request['X-CUSTOM-HEADER']
      end

      test "delegates the Rack request headers but not HTTP_HOST to avoid virtual host issues" do
        assert_nil net_http_request['HOST']
      end

      test "delegates the Rack request headers but not HTTP_CONNECTION to avoid problems with persistent connections" do
        assert_nil net_http_request['CONNECTION']
      end

      test "delegates all the content headers" do
        assert_equal @@env['CONTENT_TYPE'], net_http_request['CONTENT-TYPE']
        assert_equal @@env['CONTENT_LENGTH'], net_http_request['CONTENT-LENGTH']
      end

      test "delegates the Rack request body" do
        assert_equal '42', net_http_request.body
      end

      test "strips /prefix from the request" do
        assert_equal 'http://example.com/foo/42', net_http_request.uri.to_s
      end

      test "header_callbacks as part of header" do
        Rack::Delegate.default_headers_callback = Proc.new { |env| { 'X-Request-Id' => env['action_dispatch.request_id'] } }
        assert_equal '42', net_http_request['X-REQUEST-ID']
      end

      def net_http_request
        NetHttpRequestBuilder.new(@@request, @@uri_rewriter, @@request_rewriter).build
      end
    end
  end
end
