#!/bin/sh

# find the master db
master=`curl -L http://etcd:2379/v2/keys/service/pg-cluster/leader | jq .node.value`

# run the backup if master
envdir /etc/wal-e.d/env wal-e backup-push /data/dbnode

# Send email confirming backup was run to admin
envdir /etc/wal-e.d/env/ ~/.local/bin/aws ses send-email \
  --from "$ADMIN_EMAIL" \
  --destination "ToAddresses=$ADMIN_EMAIL" \
  --message "Subject={Data=Base backup was run,Charset=utf8},Body={Text={Data=${DB} was archived,Charset=utf8},Html={Data=${DB} was archived,Charset=utf8}}"

