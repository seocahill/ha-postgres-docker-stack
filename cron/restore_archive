#!/bin/sh
set -e

# remove any exiting data dir
rm -rf /var/lib/postgresql/data

# fetch the latest backup
envdir /etc/wal-e.d/env/ wal-e backup-fetch /var/lib/postgresql/data/ LATEST

# remove leftover patroni replication slots from backup if present
rm -rf /var/lib/postgresql/data/pg_replslot/*

# copy postgres config backups before running db
cp /var/lib/postgresql/data/postgresql.conf.backup /var/lib/postgresql/data/postgresql.conf
cp /var/lib/postgresql/data/pg_hba.conf.backup /var/lib/postgresql/data/pg_hba.conf

# copy recovery command into data folder
cat << EOF > /var/lib/postgresql/data/recovery.conf
  restore_command = 'envdir /etc/wal-e.d/env/ /usr/local/bin/wal-e wal-fetch "%f" "%p"'
EOF

# attempt to start postgres and perform test query 
pg_ctl start
NEXT_WAIT_TIME=0
TEST_QUERY="select count(1) from actor;"
until pg_isready || [ $NEXT_WAIT_TIME -eq 10 ]; do
  echo "waiting for database to start"
   sleep 5
   NEXT_WAIT_TIME=$((NEXT_WAIT_TIME + 1))
done
sleep 2
Test_RESULT=psql $DB -c "select count(1) from actor;"
pg_ctl_stop

# Send email confirming test was run to admin
envdir /etc/wal-e.d/env/ ~/.local/bin/aws ses send-email \
  --from "$ADMIN_EMAIL" \
  --destination "ToAddresses=$ADMIN_EMAIL" \
  --message "Subject={Data=Test restore from wal,Charset=utf8},Body={Text={Data=${Test_RESULT},Charset=utf8},Html={Data=${Test_RESULT},Charset=utf8}}"

