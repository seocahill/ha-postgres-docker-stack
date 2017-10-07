require 'pg'
require_relative 'test_helper'

class StackTests < MiniTest::Test
  include TestHelper

  def test_cluster_available
    master_health_check = get_request("http://haproxy:8008/master")
    replica_health_check = get_request("http://haproxy:8008/replica")
    assert_equal "running", master_health_check["state"], "Master should have a state of running"
    assert_equal "running", replica_health_check["state"], "Replica should have a state of running"
  end

  def test_replication
    master_conn = PG::Connection.connect("haproxy", 5000, '', '', "pagila", "postgres", "postgres")
    repl_conn = PG::Connection.connect("haproxy", 5001, '', '', "pagila", "postgres", "postgres")
    master_film_count = master_conn.exec("select count(*) from film;").getvalue(0,0)
    replica_film_count = repl_conn.exec("select count(*) from film;").getvalue(0,0)

    assert_equal "1000", master_film_count, "Master has correct films"
    assert_equal "1000", replica_film_count, "Replica has correct films"

    # write on master and check replica
  end

  def test_planned_failover
    skip
    # post /failover
    # check current master 
    # get('http://haproxy:8008/failover')
    # check new master
    # SELECT pg_is_in_recovery()
    # select client_addr, state, sent_location, write_location, flush_location, replay_location from pg_stat_replication;
    # check new chidlren.
  end

  def test_unplanned_failover
    skip
    # get api /services/id of master node
    # docker api /services/id DEL
    # check new master and replica up.
  end
end