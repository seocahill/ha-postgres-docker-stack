#!/bin/sh
set -e 

# switch to postgres user
su postgres

# Get the most recent backup
KEY=`envdir /etc/wal-e.d/env /home/postgres/.local/bin/aws s3 ls $DUMP_BUCKET --recursive | sort | tail -n 1 | awk '{print $4}'`
envdir /etc/wal-e.d/env /home/postgres/.local/bin/aws s3 cp $DUMP_BUCKET/$KEY /tmp/latest_backup.pgdump

# start the db 
/usr/lib/postgresql/9.6/bin/pg_ctl initdb
/usr/lib/postgresql/9.6/bin/pg_ctl start

# wait until the db is ready
NEXT_WAIT_TIME=0
until pg_isready || [ $NEXT_WAIT_TIME -eq 10 ]; do
  echo "waiting for database to start"
   sleep 5
   NEXT_WAIT_TIME=$((NEXT_WAIT_TIME + 1))
done
sleep 2

# restore db and then delete dump file
createdb $DB
pg_restore -d $DB -v -1 /tmp/latest_backup.pgdmp
rm /tmp/latest_backup.pgdump

# run a test command e.g. 
TEST_RESULT=psql $DB --c "$TEST_QUERY"

# email admin to indicate restore test was run
envdir /etc/wal-e.d/env/ /home/postgres/.local/bin/aws ses send-email \
  --from "$ADMIN_EMAIL" \
  --destination "ToAddresses=$ADMIN_EMAIL" \
  --message "Subject={Data=Dump restore was run,Charset=utf8},Body={Text={Data=${TEST_RESULT},Charset=utf8},Html={Data=${TEST_RESULT},Charset=utf8}}"

