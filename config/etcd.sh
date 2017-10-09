!# /bin/sh

etcd -name etcd \
    --data-dir /etcd_data \
    -advertise-client-urls http://etcd:2379 \
    -listen-client-urls http://0.0.0.0:2379 \
    -initial-advertise-peer-urls http://etcd:2380 \
    -listen-peer-urls http://0.0.0.0:2380 \
    -initial-cluster etcd=http://etcd:2380

# sleep 10

# etcdctl exec-watch --recursive /service/pg-cluster/leader -- sh -c 'echo "\"$ETCD_WATCH_KEY\" key was updated to \"$ETCD_WATCH_VALUE\" value by \"$ETCD_WATCH_ACTION\" action"'