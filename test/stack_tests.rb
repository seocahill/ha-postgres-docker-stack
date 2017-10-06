ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require_relative 'dummy_client'

class StackTests < MiniTest::Test

  @@client = DummyClient::Base.new

  def test_cluster_available
    health_check = @@client.get_request("http://haproxy:8008/master")
    assert_equal "running", health_check["state"], "Stack should have a state of running"
  end

  def test_replication
    replication_status = @@client.get_request("http://haproxy:8008/patroni")
    assert_equal "running", replication_status["state"], "Replication should be successful"
  end

  def test_failover
    skip
    # check current master 
    @@client.get('http://haproxy:8008/failover')
    # check new master
    # check new chidlren.
  end
end