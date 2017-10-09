# HA Postgresql cluster on docker

Todo: Detailed description of what's going on here!

Briefly: 

- High availablity: use patroni python library to orchestrate replication and automatic failover of master node.

- PIT disaster recovery: Make physical backups with Wal-e and ship to remote storage.

- Cron tasks to monitor backup and test backup restore.

- Docker compose yml for testing and production deployments of the full stack on infrastructure of choice.

### Test / Development

#### Prerequisites

Docker, wget.

Initiate swarm mode:
```
docker swarm init
```

#### Test

run ```bash scripts/run_tests.sh```

#### Development

run ```tsu``` 


### Staging

Staging setup has been tested with docker-machine on AWS and Digital Ocean

Create a cluster with AWS or digital ocean

```
cvms 
```

Login to node and make swarm manager
Join other nodes as worker
AWS only
```
sudo usermod -a -G docker $USER
```
create labels
docker stack deploy -c docker-stack.yml --with-registry-auth pg_cluster
test.

Destroy.

