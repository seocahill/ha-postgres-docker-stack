ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require_relative 'dummy_client'

class StackTests < MiniTest::Test

  @@client = DummyClient::Base.new

  def test_cluster_available
    health_check = @@client.get_request("http://haproxy:8008/master")
    assert_equal "running", health_check["state"], "Stack should have a state of running"
  end
end