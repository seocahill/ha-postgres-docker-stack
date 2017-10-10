# HA Postgresql cluster on docker

This is a docker compose file and some helper scripts to demonstrate how to deploy a highly available postgres cluster with automatic failover using docker swarm.

The complete stack is:

- docker swarm mode (orchestration)
- haproxy (endpoint for db write/reads)
- etcd (configuration, leader election)
- patroni (governs db repliation and high availability)
- postgres

Not implemented by default but present:
- wal-e log shipping to s3 
- cron:
  - logical backup and test logical backups
  - physical backup and test physical backups
- sample callback scripts for patroni events e.g. email admin on failover.

Documentation:

- [patroni](https://patroni.readthedocs.io/en/latest/index.html)
- [docker swarm mode](https://docs.docker.com/engine/swarm/)

### Test / Development

#### Prerequisites

Tested on docker 17.09.0-ce.

If you are using the deploy and test scripts you will also need to install curl, wget, awscli, and jq.

There is also a .alias file included with useful shortcut commands. Installation instructions are [here](https://github.com/sebglazebrook/aliases).

Once you have the docker daemon installed and running on you dev machine initiate swarm mode with the following command:

```
docker swarm init
```

### Test setup

A basic test suite is included that covers cluster initiation, replication and failover.

```
bash scripts/run_tests.sh [-a to keep the stack up]
```

The test setup also includes the pagila test dataset. See the steps in the test script for more details on how to load it.

###  Development

Assuming you have loaded the aliases into your shell environment you can bring the test stack by running  ```tsu```.

You can use patroni's cli to check the cluster's status 
```
pcli list pg-test-cluster
```

You can also access cluster information via http requests to the api.

```
curl localhost:8008/patroni | jq .
```

The master db is accessible on localhost:5000 and the replicas on 5001
```
psql -p 5000
```


### Staging

The staging setup has been tested with docker-machine on AWS and Digital Ocean. You will find a sample deploy script included in the scripts folder for aws deployment.

#### AWS

For deploying on AWS you will need aws cli installed, jq for json parsing and you will need to have your AWS credentials set. Docker machine will pick up on the standard aws environment variables.

```
bash scripts/deploy_aws.sh
```

With aws there are a lot of user specific variables which may prevent the script from working out of the box. Please consult the docker-machine aws plugin docs for more on how to configure your local environment.

Another option is to use Dockers cloudformation script to provision a docker ready environment from scratch on AWS.

- https://docs.docker.com/machine/drivers/aws/
- https://docs.docker.com/docker-for-aws/#docker-community-edition-ce-for-aws

#### Digital ocean

You will need to retrieve your credentials as described [here](https://docs.docker.com/machine/drivers/digital-ocean/) before preceding.

For each node run:

```
docker-machine create
    --driver digitalocean
    --digitalocean-access-token=your-secret-token
    --digitalocean-image=ubuntu-16-04-x64
    --digitalocean-region=ams-3
    --digitalocean-size=512mb
    --digitalocean-ipv6=false
    --digitalocean-private-networking=false
    --digitalocean-backups=false
    --digitalocean-ssh-user=root
    --digitalocean-ssh-port=22
  ```

The rest of the stack setup is identical to the docker commands run in the aws deploy script.


#### Virtualbox

Make sure you have allocated enough RAM to run three nodes locally and then run

```
docker-machine create --driver virtualbox node-name
```

for each node.
