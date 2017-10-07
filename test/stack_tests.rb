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
    # check dbs are in sync
    assert_equal "1000", query("master", "SELECT COUNT(*) FROM film;"), "Master has correct films"
    assert_equal "1000", query("replica", "SELECT COUNT(*) FROM film;"), "Replica has correct films"

    # update master db
    query("master", "UPDATE actor SET first_name = 'Seosamh' WHERE actor_id = 1;")
    # check if replcation has occurred
    sleep 2
    assert_equal "Seosamh",  query("replica", "SELECT first_name FROM actor WHERE actor_id = 1;"), "Replica has updated"
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