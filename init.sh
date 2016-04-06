#!/bin/bash
echo "starting ...."
wait_for_start() {
    "$@"
    while [ $? -ne 0 ]
    do
        echo 'waiting for couchbase to start'
        sleep 2
        "$@"
    done
}

# if this node should reach an existing server (a couchbase link is defined)  => env is set by docker compose link
if [ -n "${COUCHBASE_NAME:+1}" ]; then

    echo "add node to  cluster"
    # wait for couchbase clustering to be setup
    wait_for_start couchbase-cli server-list -c couchbase:8091 -u $ADMIN_LOGIN -p $ADMIN_PASSWORD
    
    echo "launch couchbase"
    /entrypoint.sh couchbase-server &

    # wait for couchbase to be up (this is the local couchbase belonging to this container)
    wait_for_start couchbase-cli server-info -c localhost:8091 -u $ADMIN_LOGIN -p $ADMIN_PASSWORD
    
    # add this new node to the cluster
    ip=`hostname --ip-address`
    #couchbase-cli server-add -c couchbase -u $ADMIN_LOGIN -p $ADMIN_PASSWORD --server-add=$ip:8091 --server-add-username=$ADMIN_LOGIN --server-add-password=$ADMIN_PASSWORD
    
    echo "node added to cluster"
    
    # wait for other node to connect to the cluster
    #sleep 10

    echo "adding and rebalancing ..."
    
    # rebalance
    couchbase-cli rebalance -c couchbase -u $ADMIN_LOGIN -p $ADMIN_PASSWORD --server-add=$ip:8091 --server-add-username=$ADMIN_LOGIN --server-add-password=$ADMIN_PASSWORD --services=data,index,query
else

    echo "launch couchbase"
    /entrypoint.sh couchbase-server &

    # wait for couchbase to be up
    wait_for_start couchbase-cli server-info -c localhost:8091 -u $ADMIN_LOGIN -p $ADMIN_PASSWORD

    echo "start initial cluster configuration"
    # init the cluster
    couchbase-cli cluster-init -c 127.0.0.1 -u $ADMIN_LOGIN -p $ADMIN_PASSWORD --cluster-init-username=${ADMIN_LOGIN} --cluster-init-password=${ADMIN_PASSWORD} --cluster-init-port=8091 --cluster-init-ramsize=${CLUSTER_RAM_QUOTA} --services=data,index,query
    
    # create bucket data
    couchbase-cli bucket-create -c 127.0.0.1 -u $ADMIN_LOGIN -p $ADMIN_PASSWORD --bucket=default --bucket-type=couchbase --bucket-ramsize=256 --wait --services=data,index,query
    
    #create bucket cache
    couchbase-cli bucket-create -c 127.0.0.1 -u $ADMIN_LOGIN -p $ADMIN_PASSWORD --bucket=cache --bucket-type=memcached --bucket-ramsize=256 --wait --services=data,index,query
    
    cat /etc/hosts


    # elasticsearch config
    wait_for_start curl elastic-couchbase:9091
    
    #configure and launch xdcr to sync with elastic
    couchbase-cli setting-xdcr -c 127.0.0.1 -u $ADMIN_LOGIN -p $ADMIN_PASSWORD
    couchbase-cli xdcr-setup -c 127.0.0.1 -u $ADMIN_LOGIN -p $ADMIN_PASSWORD -d \
           --create \
           --xdcr-cluster-name=ElasticCouchbase \
           --xdcr-hostname=elastic-couchbase:9091 \
           --xdcr-username=$ADMIN_LOGIN \
           --xdcr-password=$ADMIN_PASSWORD \
           --xdcr-from-bucket=default \
           --xdcr-to-bucket=default \
           --xdcr-replication-mode=capi
    couchbase-cli xdcr-replicate -c 127.0.0.1 -u $ADMIN_LOGIN -p $ADMIN_PASSWORD -d \
           --xdcr-cluster-name=ElasticCouchbase \
           --xdcr-from-bucket=default \
           --xdcr-to-bucket=default \
           --xdcr-replication-mode=capi
    
    
    
    # Rebalancing could also be done here, but then a killed container doesn't rebalance automatically
    # wait for other node to connect to the cluster
    #sleep 10
    
    # rebalance
    # couchbase-cli rebalance -c 127.0.0.1 -u $ADMIN_LOGIN -p $ADMIN_PASSWORD    
fi
        
wait
