#!/bin/bash

# For testing create the dbs network externally and allow other containers to attach
docker network create -d overlay --attachable dbs
docker stack deploy -c docker-stack.test.yml test_pg_cluster
printf '\nwaiting for stack to boot';

TRIES=0

until $(wget --spider http://0.0.0.0:8008 2>/dev/null) || [ $TRIES -eq 15 ]; do
  (( TRIES++ ))
  printf '.';
  sleep 2;
done

if [ $TRIES -eq 15 ]; then
  printf '\nno response from server'
else
  printf '\nloading test data\n'
  PGPASSWORD=postgres psql -h localhost -U postgres -p 5000 postgres -c "create database pagila;"
  PGPASSWORD=postgres psql -h localhost -U postgres -p 5000 pagila < $PWD/test/data/pagila-schema.sql
  PGPASSWORD=postgres psql -h localhost -U postgres -p 5000 pagila < $PWD/test/data/pagila-data.sql
  printf '\nrunning tests\n'
  docker run --rm -v `pwd`:`pwd` -w `pwd` --network=dbs -i -t seocahill/ruby-postgres-alpine:0.1 ruby test/stack_tests.rb
  printf '\ndone!'
fi

if [ "$1" == "-a" ]; then
  printf '\nstack still up!\n';
else
  printf '\nstopping services\n';
  sleep 5;
  docker stack rm test_pg_cluster
  docker network rm dbs
fi
