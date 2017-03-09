#!/bin/bash
# Not yet working!!!!
# TODO

x=-1

while [ "$x" != "3" ]
do
   curl --silent -u "$ADMIN_LOGIN:$ADMIN_PASSWORD" http://localhost:8091/pools/default | python -mjson.tool | grep "status" > tmpfile
   cat tmpfile
   x=`cat tmpfile | wc -l`
   echo "Nodes now status: " $x
   sleep 2
done

echo "All three nodes healthy"
