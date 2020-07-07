while [[ "$status" != *"healthy"* ]]
do
    echo "=========================================================="
    echo "Waiting on couchbase to finish setup and become healthy..."
    
    # Nasty way to parse json with sed rather than installing 
    # extra tools in the VM for this one tiny thing.
    status=`curl -u "$ADMIN_LOGIN:$ADMIN_PASSWORD" http://localhost:8091/pools/default 2>/dev/null | sed 's/.*status\"://g' | sed 's/,.*//'`
    echo "Cluster status " $status `date`
    sleep 2
done