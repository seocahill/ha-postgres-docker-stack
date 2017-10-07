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
    # returns domain names of each db node i.e. one of dbnode1, dbnode2 or dbnode3 which also match patroni member names
    master = lookup_master
    candidate = lookup_replicas.first
    
    # Initiate failover 
    response = post_request('http://haproxy:8008/failover', { "leader": master, "candidate": candidate })
    assert_equal response.code, '200', "Failover initiated"

    # Failover might take a few seconds to complete
    # need new db connection I think
    new_master = lookup_master
    until new_master
      puts "waiting for failover to conclude"
      sleep 5
      new_master = lookup_master
    end
    
    # check old master is demoted and replica promoted
    assert_equal candidate, new_master, "Replica has been promoted to master"
    refute_includes replicas, candidate, "Replicas do not contain candidate"

    # check for split brain
    assert_false node_in_recovery?(candidate), "New master not in recovery"
    assert_true node_in_recovery?(master), "Old master in recovery"

    # check sync
    master_log = query("master", "SELECT pg_current_xlog_location();")
    replica_log = query("replica", "SELECT pg_last_xlog_receive_location();")
    assert_equal master_log, repolica_log, "Cluster in sync"
  end

  def test_unplanned_failover
    skip "use docker api to delete master node service and test failover"
  end
end