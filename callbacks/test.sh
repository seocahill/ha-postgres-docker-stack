# log the callback details
echo "$1 callback triggered by $PATRONI_NAME $0 on $HOST_NAME"> /var/log/patroni_event.log 2>&1
