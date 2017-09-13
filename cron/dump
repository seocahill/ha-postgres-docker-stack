#!/bin/sh
set -e

TIME=$( date +%s )
FILENAME="$DB"_"$TIME".pgdmp

# find dbnode, run the dump and send it to s3.
docker exec -i $(docker ps -f name=dbnode -q) /bin/bash <<EOF
  pg_dump -d $DB -n public --format=custom -f /tmp/$FILENAME
  envdir /etc/wal-e.d/env /home/postgres/.local/bin/aws s3 cp /tmp/$FILENAME $DUMP_BUCKET/
  rm /tmp/$FILENAME
EOF

# Send email confirming backup was run to admin
envdir /etc/wal-e.d/env/ ~/.local/bin/aws ses send-email \
  --from "$ADMIN_EMAIL" \
  --destination "ToAddresses=$ADMIN_EMAIL" \
  --message "Subject={Data=Pg dump was run,Charset=utf8},Body={Text={Data=${DB} was dumped,Charset=utf8},Html={Data=${DB} was dumped,Charset=utf8}}"

