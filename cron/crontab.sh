#!/bin/sh

# setup direnv for wal-e or aws
cat /run/secrets/aws_access_key_id > /etc/wal-e.d/env/AWS_ACCESS_KEY_ID
cat /run/secrets/aws_region > /etc/wal-e.d/env/AWS_REGION
cat /run/secrets/aws_default_region > /etc/wal-e.d/env/AWS_DEFAULT_REGION
cat /run/secrets/aws_secret_access_key > /etc/wal-e.d/env/AWS_SECRET_ACCESS_KEY
cat /run/secrets/wale_s3_prefix > /etc/wal-e.d/env/WALE_S3_PREFIX

# copy whatever scripts you need into place
cp /run/secrets/cron_dump /etc/cron.daily
cp /run/secrets/cron_restore_dump /etc/cron.weekly
cp /run/secrets/cron_archive /etc/cron.daily
cp /run/secrets/cron_restore_archive /etc/cron.weekly

# make sure they are executable
chmod a+x /etc/cron.daily/cron_dump
chmod a+x /etc/cron.daily/cron_archive
chmod a+x /etc/cron.weekly/cron_restore_dump
chmod a+x /etc/cron.weekly/cron_restore_archive

# run cron in the foreground
cron -f