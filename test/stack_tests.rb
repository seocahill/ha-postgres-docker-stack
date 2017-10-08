require_relative 'test_helper'
require 'timeout'

class StackTests < MiniTest::Test
  include TestHelper
  
  def test_cluster_available
    response = get_request("http://haproxy:8008/master")
    assert_equal "200", response.code, "Master responds with 200"
    assert_equal "running", JSON.parse(response.body)["state"], "Master should have a state of running"

    response = get_request("http://haproxy:8008/replica")
    assert_equal "200", response.code, "Replica responds with 200"
    assert_equal "running", JSON.parse(response.body)["state"], "Replica should have a state of running"
  end

  def test_replication
    # check dbs are in sync
    assert_equal "1000", query("master", "SELECT COUNT(*) FROM film;").getvalue(0,0), "Master has correct films"
    assert_equal "1000", query("replica", "SELECT COUNT(*) FROM film;").getvalue(0,0), "Replica has correct films"

    # update master db
    query("master", "UPDATE actor SET first_name = 'Seosamh' WHERE actor_id = 1;")
    # check if replcation has occurred
    sleep 2
    assert_equal "Seosamh",  query("replica", "SELECT first_name FROM actor WHERE actor_id = 1;").getvalue(0,0), "Replica has updated"
  end

  def test_planned_failover
    # returns domain names of each db node i.e. one of dbnode1, dbnode2 or dbnode3 which also match patroni member names
    master = lookup_master
    candidate = lookup_replicas.first
    
    # Initiate failover 
    response = post_request('http://haproxy:8008/failover', { "leader": master, "candidate": candidate })
    assert_equal response.code, '200', "Failover initiated"

    # Failover might take a few seconds to complete
    puts "\nwaiting for failover to conclude"
    begin
      Timeout::timeout(30) {
        until JSON.parse(get_request("http://haproxy:8008/master").body).has_key?("replication")
          puts "."
          sleep 3
        end
      }
    rescue TimeoutError
      puts "Timeout waiting for failover to finish"
    end
    
    # check old master is demoted and replica promoted
    new_master = lookup_master
    replicas = lookup_replicas
    assert_equal candidate, new_master, "Replica has been promoted to master"
    refute_includes replicas, candidate, "Replicas do not contain candidate"

    # check for split brain
    refute node_in_recovery?(candidate), "New master not in recovery"
    assert node_in_recovery?(new_master), "Old master in recovery"

    # check sync
    master_log = query("master", "SELECT pg_current_xlog_location();").getvalue(0,0)
    replica_log = query("replica", "SELECT pg_last_xlog_receive_location();").getvalue(0,0)
    assert_equal master_log, repolica_log, "Cluster in sync"
  end

  def test_unplanned_failover
    skip "use docker api to delete master node service and test failover"
  end
end