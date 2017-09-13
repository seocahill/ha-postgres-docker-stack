#!/bin/bash

cat /run/secrets/aws_access_key_id > /etc/wal-e.d/env/AWS_ACCESS_KEY_ID
cat /run/secrets/aws_region > /etc/wal-e.d/env/AWS_REGION
cat /run/secrets/aws_default_region > /etc/wal-e.d/env/AWS_DEFAULT_REGION
cat /run/secrets/aws_secret_access_key > /etc/wal-e.d/env/AWS_SECRET_ACCESS_KEY
cat /run/secrets/wale_s3_prefix > /etc/wal-e.d/env/WALE_S3_PREFIX

cat /run/secrets/notification.py > /home/postgres/notification.py
cat /run/secrets/notification.sh > /home/postgres/notification.sh

chmod a+x /home/postgres/notification.py
chmod a+x /home/postgres/notification.sh

mkdir -p "$HOME/.config/patroni"
[ -h "$HOME/.config/patroni/patronictl.yaml" ] || ln -s /patroni.yml "$HOME/.config/patroni/patronictl.yaml"

exec "$@"