require 'test_helper'
require 'webmock/minitest'

module Rack
  module Delegate
    class DelegatorTest < Minitest::Test
      @@url = 'http://example.com/prefix/foo/42'
      @@env = Rack::MockRequest.env_for(@@url,
        'REQUEST_METHOD' => 'POST',
        'REMOTE_ADDR' => '123.123.123.123',
        'HTTP_X_CUSTOM_HEADER' => '42',
        'HTTP_HOST' => 'example.com',
        'HTTP_CONNECTION' => 'Keep-Alive',
        'CONTENT_TYPE' => 'application/json',
        'CONTENT_LENGTH' => '2',
        'rack.input' => StringIO.new('42')
      )

      @@request = Rack::Request.new(@@env)
      @@uri_rewriter = Rewriter.new { |u| u.path = u.path.gsub('/prefix', ''); u }
      @@request_rewriter = Rewriter.new
      @@error_response = NetworkErrorResponse
      @@delegator = Delegator.new(@@url, @@uri_rewriter, @@request_rewriter, @@error_response, {})

      def net_http_stub_request
        stub_request(:post, "http://example.com/foo/42").
          with(:body => "42",
               :headers => {'Content-Length'=>'2', 'Content-Type'=>'application/json', 'X-Custom-Header'=>'42'}).
          to_return(:status => 200, :body => '', :headers => { 'x-request-id': '42', 'transfer-encoding': 'chunked', 'status': '400' })
      end

      test "returns response with proper header" do
        net_http_stub_request
        assert_equal(["200", { 'x-request-id' => '42' }, [] ], @@delegator.call(@@env))
      end

      test "will not return transfer-encoding header in response" do
        net_http_stub_request
        assert_nil @@delegator.call(@@env)[1]['transfer-encoding']
      end
    end
  end
end
