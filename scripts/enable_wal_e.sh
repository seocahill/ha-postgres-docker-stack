#!/bin/bash

# find the ip of the manager
HOST_IP=`docker-machine ip $0`

# update config with wal-e settings
curl -u admin:admin  \
  -s -XPATCH \
  -H 'Content-Type:application/json' \
  -H 'Accept: application/json' \
  -d @config/wal-e.json \
  http://$HOST_IP:8008/config | jq .

# checking status should see pending restart
curl http://$HOST_IP:8008 | jq .

# restart the cluster
curl -u admin:admin -s -X POST http://$HOST_IP:8008/restart | jq .