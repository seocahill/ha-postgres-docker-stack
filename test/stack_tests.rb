ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require_relative 'dummy_client'
require 'pg'

class StackTests < MiniTest::Test

  @@client = DummyClient::Base.new

  def test_cluster_available
    master_health_check = @@client.get_request("http://haproxy:8008/master")
    replica_health_check = @@client.get_request("http://haproxy:8008/replica")
    assert_equal "running", master_health_check["state"], "Master should have a state of running"
    assert_equal "running", replica_health_check["state"], "Replica should have a state of running"
  end

  def test_replication
    master_conn = PGconn.connect("haproxy", 5000, '', '', "pagila", "postgres", "postgres")
    master_film_count = master_conn.exec("select count(*) from film;").getvalue(0,0)
    repl_conn = PGconn.connect("haproxy", 5001, '', '', "pagila", "postgres", "postgres")
    replica_film_count = repl_conn.exec("select count(*) from film;").getvalue(0,0)

    assert_equal "1000", master_film_count, "Master has correct films"
    assert_equal "1000", replica_film_count, "Replica has correct films"

    # write on master and check replica
  end

  def test_failover
    skip
    # check current master 
    # @@client.get('http://haproxy:8008/failover')
    # check new master
    # check new chidlren.
  end
end