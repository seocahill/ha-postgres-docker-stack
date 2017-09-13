# HA Postgresql cluster on docker

Todo: Detailed description of what's going on here!

Briefly: 

- High availablity: use patroni python library to orchestrate replication and automatic failover of master node.

- PIT disaster recovery: Make physical backups with Wal-e and ship to remote storage.

- Cron tasks to monitor backup and test backup restore.

- Docker compose yml for testing and production deployments of the full stack on infrastructure of choice.

