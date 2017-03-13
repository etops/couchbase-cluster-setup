#!/bin/bash

DIR=./test-queries
AUTH="$ADMIN_LOGIN:$ADMIN_PASSWORD"
URL=http://localhost:8093/query/service

curl -u $AUTH $URL -d "statement=select count(*) from models" | python -mjson.tool > $DIR/count-star.json
curl -u $AUTH $URL -d "statement=select count(*) from models where _type='Portfolio'" | python -mjson.tool > $DIR/portfolios.json
curl -u $AUTH $URL -d "statement=select * from system:indexes" | python -mjson.tool > $DIR/indexes.json
