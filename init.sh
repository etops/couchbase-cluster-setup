#!/bin/bash
#
# This script configures the couchbase cluster for running.
# 
# It uses the couchbase command line tool, docs here:
# http://developer.couchbase.com/documentation/server/current/cli/cbcli-intro.html
#
# Which buckets, how much RAM -- necessary docs are in Sizing Guidelines
# http://developer.couchbase.com/documentation/server/current/install/sizing-general.html
#
#
echo "starting ...."
echo "using client at " `which couchbase-cli`
wait_for_success() {
    "$@"
    while [ $? -ne 0 ]
    do
        echo 'waiting for couchbase to start'
        sleep 2
        "$@"
    done
}

wait_for_healthy() {
    status="beats me"

    while [[ "$status" != *"healthy"* ]]
    do
        echo "Waiting on couchbase to finish setup and become healthy..."
        
        # Nasty way to parse json with sed rather than installing 
        # extra tools in the VM for this one tiny thing.
        status=`curl -u "$ADMIN_LOGIN:$ADMIN_PASSWORD" http://$HOST:$PORT/pools/default 2>/dev/null | sed 's/.*status\"://g' | sed 's/,.*//'`
        echo "Cluster status " $status `date`
        sleep 2
    done

    echo "Healthy"
}

if [ -z "$CLUSTER_RAM_QUOTA" ] ; then
    echo "Missing cluster ram quota, setting to 1024"
    export CLUSTER_RAM_QUOTA=512 ; 
fi

if [ -z "$INDEX_RAM_QUOTA" ] ; then
    echo "Missing index ram quota; setting to 256"
    export INDEX_RAM_QUOTA=256 ;
fi

HOST=localhost
PORT=8091

# Model bucket configuration options.
# Give this one more memory, so it can cache 
# more, faster access.
MODEL_BUCKET=models

if [ -z "$MODEL_BUCKET_RAMSIZE" ] ; then
   echo "Missing model bucket ramsize; setting to 256"
   MODEL_BUCKET_RAMSIZE=256 ;
fi

# File bucket configuration options.
# Memory can be much lower because it's not important to 
# keep a resident set in memory for fast query/access.
FILE_BUCKET=files

if [ -z "$FILE_BUCKET_RAMSIZE" ] ; then
   echo "Missing file bucket ramsize; setting to 128"
   FILE_BUCKET_RAMSIZE=128 ;
fi

# if this node should reach an existing server (a couchbase link is defined)  => env is set by docker compose link
if [ -n "${COUCHBASE_NAME:+1}" ]; then

    echo "add node to cluster"
    # wait for couchbase clustering to be setup
    wait_for_success curl -v -u "$ADMIN_LOGIN:$ADMIN_PASSWORD" $HOST:$PORT/pools/default -C -
    
    echo "launch couchbase"
    /entrypoint.sh couchbase-server &

    # wait for couchbase to be up (this is the local couchbase belonging to this container)
    wait_for_success couchbase-cli server-info -c $HOST:$PORT -u $ADMIN_LOGIN -p $ADMIN_PASSWORD
    
    # add this new node to the cluster
    ip=`hostname --ip-address`
    #couchbase-cli server-add -c couchbase -u $ADMIN_LOGIN -p $ADMIN_PASSWORD --server-add=$ip:$PORT --server-add-username=$ADMIN_LOGIN --server-add-password=$ADMIN_PASSWORD
    
    echo "node added to cluster"
    
    # wait for other node to connect to the cluster
    #sleep 10

    echo "adding and rebalancing ..."
    
    # rebalance
    couchbase-cli rebalance -c couchbase \
        -u $ADMIN_LOGIN -p $ADMIN_PASSWORD \
        --server-add=$ip:$PORT \
        --server-add-username=$ADMIN_LOGIN \
        --server-add-password=$ADMIN_PASSWORD \
        --services=data,index,query

   wait_for_healthy
else

    echo "Launching Couchbase..."
    /entrypoint.sh couchbase-server &

    # wait for couchbase to be up
    # This is not sufficient to know that the cluster is healthy and ready to accept queries,
    # but it indicates the REST API is ready to take configuration settings.
    wait_for_success curl -v -u "$ADMIN_LOGIN:$ADMIN_PASSWORD" $HOST:$PORT/pools/default -C -
    
    # init the cluster
    # It's very important to get these arguments right, because after
    # a cluster is provisioned, some parameters (like services) cannot
    # be changed.
    echo "Initializing cluster configuration ..."
    couchbase-cli cluster-init -c $HOST \
        -u $ADMIN_LOGIN -p $ADMIN_PASSWORD \
        --cluster-username=${ADMIN_LOGIN} \
        --cluster-password=${ADMIN_PASSWORD} \
        --cluster-port=$PORT \
        --cluster-ramsize=$CLUSTER_RAM_QUOTA \
        --cluster-index-ramsize=$INDEX_RAM_QUOTA \
	--index-storage-setting=default \
        --services=data,index,query
  
    # Create bucket for model data
    echo "Creating bucket " $MODEL_BUCKET " ..."
    couchbase-cli bucket-create -c $HOST \
        -u $ADMIN_LOGIN -p $ADMIN_PASSWORD \
        --bucket=$MODEL_BUCKET \
        --bucket-type=couchbase \
        --bucket-ramsize=$MODEL_BUCKET_RAMSIZE \
        --wait 

    # Set model bucket to be high priority
    echo "Setting " $MODEL_BUCKET " bucket to be high priority..."
    couchbase-cli bucket-edit -c $HOST \
        -u $ADMIN_LOGIN -p $ADMIN_PASSWORD \
        --bucket=$MODEL_BUCKET \
        --bucket-priority=high

    # Do not include index, query services because they 
    # require memory and aren't needed.
    echo "Creating bucket " $FILE_BUCKET " ..."
    couchbase-cli bucket-create -c $HOST \
        -u $ADMIN_LOGIN -p $ADMIN_PASSWORD \
        --bucket=$FILE_BUCKET \
        --bucket-type=couchbase \
        --bucket-ramsize=$FILE_BUCKET_RAMSIZE \
        --wait 

    echo "Setting " $FILE_BUCKET " bucket to be low priority..."
    couchbase-cli bucket-edit -c $HOST \
        -u $ADMIN_LOGIN -p $ADMIN_PASSWORD \
        --bucket=$FILE_BUCKET \
        --bucket-priority=low

    echo "Configuring index settings..."
    couchbase-cli setting-index -c $HOST \
        -u $ADMIN_LOGIN -p $ADMIN_PASSWORD \
        --index-max-rollback-points=5 \
        --index-memory-snapshot-interval=200 \
        --index-threads=2          

    # For debug purposes in logs, show buckets.
    echo "Inspecting bucket list..."
    couchbase-cli bucket-list -c $HOST \
        -u $ADMIN_LOGIN -p $ADMIN_PASSWORD

    echo "Inspecting server list..."
    couchbase-cli server-list -c $HOST \
        -u $ADMIN_LOGIN -p $ADMIN_PASSWORD

    echo "Cluster info after startup..."
    curl -u "$ADMIN_LOGIN:$ADMIN_PASSWORD" http://$HOST:$PORT/pools

    echo "Cluster internal settings after startup..."
    curl -u "$ADMIN_LOGIN:$ADMIN_PASSWORD" http://$HOST:$PORT/internalSettings

    # Email alerts (not used, TBD)
    # http://developer.couchbase.com/documentation/server/current/cli/cbcli/setting-alert.html
    # couchbase-cli setting-alert -c $HOST \
    #     -u $ADMIN_LOGIN -p $ADMIN_PASSWORD \
    #     --enable-email-alert=1 \
    #     --email-recipients=devops@etops.ch,software@etops.ch \
    #     --email-sender=SENDER \
    #     --email-user=USER \
    #     --email-password=PWD \
    #     --email-host=HOST \
    #     --email-port=PORT \
    #     --enable-email-encrypt=0 \
    #     --alert-auto-failover-node \
    #     --alert-auto-failover-max-reached \
    #     --alert-auto-failover-node-down \
    #     --alert-auto-failover-cluster-small \
    #     --alert-auto-failover-disabled \
    #     --alert-ip-changed \
    #     --alert-disk-space \
    #     --alert-meta-overhead \
    #     --alert-meta-oom \
    #     --alert-write-failed

    # create bucket cache
    # as yet is unused and couchbase may come up and be ready faster without this
    # couchbase-cli bucket-create -c $HOST -u $ADMIN_LOGIN -p $ADMIN_PASSWORD --bucket=cache --bucket-type=memcached --bucket-ramsize=256 --wait --services=data,index,query

    # Rebalancing could also be done here, but then a killed container doesn't rebalance automatically
    # wait for other node to connect to the cluster
    #sleep 10
    
    # rebalance
    # couchbase-cli rebalance -c $HOST -u $ADMIN_LOGIN -p $ADMIN_PASSWORD

    wait_for_healthy

    echo "Finished with cluster setup/config."
fi
        
wait
