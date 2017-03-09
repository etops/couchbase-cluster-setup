#!/bin/bash

status="beats me"

while [[ "$status" != *"healthy"* ]] 
do
    echo "Checking cluster health..."
    status=`curl --silent -u "$ADMIN_LOGIN:$ADMIN_PASSWORD" http://localhost:8091/pools/default 2>/dev/null | sed 's/.*status\"://g' | sed 's/,.*//'`
    echo "Cluster status " $status `date`
    sleep 2
done

echo "Healthy"