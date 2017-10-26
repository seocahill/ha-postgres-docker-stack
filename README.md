# HA Postgresql cluster on docker

This is a docker compose file and some helper scripts to demonstrate how to deploy a highly available postgres cluster with automatic failover using docker swarm. 

I've written some blog posts that explain what's happening here in more depth, you can find them here:
- [part 1](https://blog.seocahill.com/docker-postgres-cluster-with-high-availability-and-disaster-recovery)
- [part 2](https://blog.seocahill.com/docker-postgres-cluster-with-high-availability-and-disaster-recovery-part-2)

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


[![asciicast](https://asciinema.org/a/8raWQiIA4bAVxsuLsjw7O84U9.png)](https://asciinema.org/a/8raWQiIA4bAVxsuLsjw7O84U9?size=medium&speed=2)

### Test / Development 

Use the ```docker-stack.test.yml``` when running the suite or testing the stack on docker for mac for example.

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

First copy the test env template to test.env
```
cp test.env.tmpl test.env
```

Patroni will not boot without these environment variables present.

Run the test suite with

```
scripts/run_tests.sh [-a to keep the stack up]
```

The test setup also includes the pagila test dataset. See the steps in the test script for more details on how to load it.

###  Development

Assuming you have loaded the aliases into your shell environment you can bring the test stack by running 

```
tsu
```

If you want to use ```docker-stack.yml``` instead you'll need to remove the deploy restriction conditions or else the services will never start.

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

#### Environment variables

The staging setup is slightly different to the test stack in that each dbnode expects its own env file to be present at the root of the repo e.g. db-1.env

The absolute minimum setup required to get the stack up is a combination of the inline environment variables from ```docker-stack.test.yml``` and those in ```test.env.tmpl```. 

For full configuration options consult the patroni documentation.

#### AWS

For deploying on AWS you will need aws cli installed, jq for json parsing and you will need to have your AWS credentials set. Docker machine will pick up on the standard aws environment variables.

```
scripts/deploy_aws.sh
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

### Deploying the stack

Make sure you are executing these commands in the context of your node manager:

```
eval $(docker-machine env db-1)
```

To deploy your stack run

```
docker stack deploy -c docker-stack.yml pg_cluster
```

To check the state of your services run

```
docker service ls
```

For logs run:
```
docker service logs pg_cluster_haproxy 
```

### Cleanup

Remove the hosts:
```
docker-machine rm db-1 db-2 db-3
```

Reset your docker environment:

```
eval $(docker-machine env --unset)
```
